{ lib, config, pkgs, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg = config.settings.maintenance;
  sys_cfg = config.settings.system;
  tunnel_cfg = config.settings.reverse_tunnel;

  # Submodule to define repos.
  repoOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };
      branch = mkOption {
        type = types.str;
      };
      url = mkOption {
        type = types.str;
      };
    };
    config = {
      name = mkDefault name;
    };
  };
in {

  # https://github.com/NixOS/nixpkgs/pull/77622
  imports = [ ./nixos-upgrade.nix ];

  options.settings.maintenance = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    sync_config.enable = mkOption {
      type        = types.bool;
      default     = true;
      description = ''
        Whether to pull the config from the upstream branch before running the upgrade service.
      '';
    };

    config_repos = mkOption {
      type    = with types; attrsOf (submodule repoOpts);
      default = {};
    };

    docker_prune_timer.enable = mkEnableOption "service to periodically run docker system prune";
  };

  config = mkIf cfg.enable {
    settings.maintenance.config_repos = {
      main = {
        branch = "master";
        url = "git@github.com:MSF-OCB/NixOS-config.git";
      };
      org = {
        branch = "master";
        url = "git@github.com:MSF-OCB/NixOS-OCB-config.git";
      };
    };

    system.autoUpgrade = {
      enable       = true;
      allowReboot  = true;
      rebootWindow = { lower = "01:00"; upper = "05:00"; };
      # We override this below, since this option does not accept
      # a list of multiple timings.
      dates        = "";
    };

    systemd.services = {
      nixos-upgrade = {
        serviceConfig = {
          TimeoutStartSec = "2 days";
        };
        # We run the upgrade service once at night and twice during the day,
        # to catch the situation where the server is turned off during the night
        # or during the weekend (which can be anywhere from Thursday to Sunday).
        # When the service is being run during the day, we will be outside the
        # reboot window and the config will not be switched.
        startAt = mkForce [ "Fri 12:00" "Sun 12:00" "Mon 02:00" ];
      };

      nixos_sync_config = mkIf cfg.sync_config.enable {
        description   = "Automatically sync the config with the upstream repository";
        before        = [ "nixos-upgrade.service" ];
        wantedBy      = [ "nixos-upgrade.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        environment = {
          GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh " +
                            "-i ${tunnel_cfg.private_key} " +
                            "-o IdentitiesOnly=yes " +
                            "-o StrictHostKeyChecking=yes";
        };
        script = let
          base_path = "/etc/nixos";
          config_path = "${base_path}/${sys_cfg.org_config_dir_name}";
          old_config_path = "${base_path}/ocb-config";

          hostname         = config.networking.hostName;
          settings_path    = "/etc/nixos/settings.nix";
          destination_path = "/etc/nixos/${sys_cfg.org_config_dir_name}/hosts/${hostname}.nix";
        in ''
          # Main repo

          ${msf_lib.reset_git { inherit (cfg.config_repos.main) branch;
                                git_options = [ "-C" base_path ]; }}

          # Organisation-specific repo

          if [ ! -d "${config_path}" ] && [ -d "${old_config_path}" ]; then
            mv "${old_config_path}" "${config_path}"
          fi

          if [ ! -d "${config_path}" ] || [ ! -d "${config_path}/.git" ]; then
            rm --recursive --force "${config_path}"
            ${pkgs.git}/bin/git clone ${cfg.config_repos.org.url} "${config_path}"
          fi

          if [ -d "${old_config_path}" ]; then
            rm --recursive --force "${old_config_path}"
          fi

          ${msf_lib.reset_git { inherit (cfg.config_repos.org) branch;
                                git_options = [ "-C" config_path ]; }}

          # Settings link

          function create_link() {
            destination="''${1}"
            if [ ! -f "${settings_path}" ] || \
               [ "$(realpath ${settings_path})" != "''${destination}" ]; then
              ln --force --symbolic "''${destination}" "${settings_path}"
            fi
          }

          if [ -f "${settings_path}" ] && [ ! -L "${settings_path}" ]; then
            rm --force "${settings_path}"
          fi
          create_link "${destination_path}"
        '';
      };

      nixos_decrypt_secrets = {
        description   = "Decrypt the server secrets";
        after         = [ "nixos-upgrade.service" ];
        wantedBy      = [ "nixos-upgrade.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        environment = {
          # We need to set the NIX_PATH env var so that we can resolve <nixpkgs>
          inherit (config.environment.sessionVariables) NIX_PATH;
        };
        script = let
          python = pkgs.python3.withPackages (pkgs: with pkgs; [ pynacl pyyaml ]);
        in ''
          ${python.interpreter} \
            ${../scripts/decrypt_server_secrets.py} \
            --server_name "${config.networking.hostName}" \
            --secrets_path "${sys_cfg.secrets_src_directory}" \
            --output_path "${sys_cfg.secretsDirectory}" \
            --private_key_file "${tunnel_cfg.private_key}"
          chown --recursive root:wheel "${sys_cfg.secretsDirectory}"
          chmod --recursive u=rwX,g=rX,o= "${sys_cfg.secretsDirectory}"
        '';
      };

      nixos_rebuild_config = {
        description   = "Rebuild the NixOS config without doing an upgrade";
        serviceConfig = {
          Type = "oneshot";
        };

        restartIfChanged = false;
        unitConfig.X-StopOnRemoval = false;

        environment = config.nix.envVars //
          { inherit (config.environment.sessionVariables) NIX_PATH;
            HOME = "/root";
          } // config.networking.proxy.envVars;

        path = with pkgs; [ coreutils gnutar xz.bin gzip gitMinimal config.nix.package.out ];

        script = let
          upgrade_cfg = config.system.autoUpgrade;
          nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
          date     = "${pkgs.coreutils}/bin/date";
          readlink = "${pkgs.coreutils}/bin/readlink";
          shutdown = "${pkgs.systemd}/bin/shutdown";
        in ''
          ${nixos-rebuild} boot --no-build-output

          booted="$(${readlink} /run/booted-system/{initrd,kernel,kernel-modules})"
          built="$(${readlink} /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"
          ${optionalString (upgrade_cfg.rebootWindow != null) ''current_time="$(${date} +%H:%M)"''}

          if [ "$booted" = "$built" ]; then
            ${nixos-rebuild} switch
          ${optionalString (upgrade_cfg.rebootWindow != null) ''
            elif [[ "''${current_time}" < "${upgrade_cfg.rebootWindow.lower}" ]] || \
                 [[ "''${current_time}" > "${upgrade_cfg.rebootWindow.upper}" ]]; then
              echo "Outside of configured reboot window, skipping."
          ''}
          else
            ${shutdown} -r +1
          fi
        '';
      };

      cleanup_auto_roots = {
        description   = "Automatically clean up nix auto roots";
        before        = [ "nix-gc.service" ];
        wantedBy      = [ "nix-gc.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          find /nix/var/nix/gcroots/auto/ -type l -mtime +30 | while read fname; do
            target=$(readlink ''${fname})
            if [ -L ''${target} ]; then
              unlink ''${target}
            fi
          done
        '';
      };

      docker_prune_timer = mkIf cfg.docker_prune_timer.enable {
        inherit (cfg.docker_prune_timer) enable;
        description   = "Automatically run docker system prune";
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${pkgs.docker}/bin/docker system prune --force
        '';
        startAt = "Wed 04:00";
      };
    };

    nix = {
      autoOptimiseStore = true;
      gc = {
        automatic = true;
        dates     = "Tue 03:00";
        options   = "--delete-older-than 30d";
      };
    };
  };
}

