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

    # We run the upgrade service once at night and once during the day, to catch the situation
    # where the server is turned off every evening.
    # When the service is being run during the day, we will be outside of the reboot window.
    system.autoUpgrade = {
      enable       = true;
      allowReboot  = true;
      rebootWindow = { lower = "01:00"; upper = "05:00"; };
      # Run the service at 02:00 during the night and at 12:00 during the day
      dates        = "Mon 02,12:00";
    };

    systemd.services = {
      nixos-upgrade.serviceConfig = {
        TimeoutStartSec = "2 days";
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
        '';
      };

      nixos_rebuild_config = {
        description   = "Rebuild the NixOS config without doing an upgrade";
        after         = [ "nixos_sync_config.service" ];
        wants         = [ "nixos_sync_config.service" ];
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

