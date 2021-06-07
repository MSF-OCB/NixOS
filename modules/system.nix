{ config, lib, pkgs, ... }:

let
  cfg     = config.settings.system;
  tnl_cfg = config.settings.reverse_tunnel;
in

with lib;

{
  options.settings.system = {
    nix_channel = mkOption {
      type = types.str;
    };

    isISO = mkOption {
      type = types.bool;
      default = false;
    };

    private_key_source = mkOption {
      type    = types.path;
      default = ../local/id_tunnel;
      description = ''
        The location of the private key file used to establish the reverse tunnels.
      '';
    };

    private_key_source_default = mkOption {
      type     = types.str;
      default  = "/etc/nixos/local/id_tunnel";
      readOnly = true;
      description = ''
        Hard-coded value of the default location of the private key file,
        used in case the location specified at build time is not available
        at activation time, e.g. when the build was done from within the
        installer with / mounted on /mnt.
        This value is only used in the activation script.
      '';
    };

    private_key_directory = mkOption {
      type     = types.str;
      default  = "/run/tunnel";
      readOnly = true;
    };

    private_key = mkOption {
      type     = types.str;
      default  = "${cfg.private_key_directory}/id_tunnel";
      readOnly = true;
      description = ''
        Location to load the private key file for the reverse tunnels from.
      '';
    };

    copy_private_key_to_store = mkOption {
      type    = types.bool;
      default = false;
      description = ''
        Whether the private key for the tunnels should be copied to
        the nix store and loaded from there. This should only be used
        when the location where the key is stored, will not be available
        during activation time, e.g. when building an ISO image.
        CAUTION: this means that the private key will be world-readable!
      '';
    };

    org_config_dir_name = mkOption {
      type = types.str;
      default = "org-config";
      readOnly = true;
      description = ''
        WARNING: when changing this value, you need to change the corresponding
                 values in install.sh and modules/default.nix as well!
      '';
    };

    users_json_path = mkOption {
      type = types.path;
    };

    tunnels_json_path = mkOption {
      type = types.path;
    };

    pub_keys_path = mkOption {
      type = types.path;
    };

    secrets = {
      src_directory = mkOption {
        type = types.path;
        description = ''
          The directory containing the generated and encrypted secrets.
        '';
      };

      dest_directory = mkOption {
        type = types.str;
        description = ''
          The directory containing the decrypted secrets available to this server.
        '';
      };

      old_dest_directories = mkOption {
        type = with types; listOf str;
        default = [];
      };

      allow_groups = mkOption {
        type = with types; listOf str;
        description = ''
          Groups which have access to the secrets through ACLs.
        '';
        default = [];
      };
    };

    diskSwap = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };

      size = mkOption {
        type = types.ints.between 0 10;
        default = 1;
        description = "Size of the swap partition in GiB.";
      };
    };
  };

  config = {

    assertions = [
      {
        assertion = hasAttr config.networking.hostName tnl_cfg.tunnels;
        message   = "This host's host name is not present in the tunnel config (${toString cfg.tunnels_json_path}).";
      }
      {
        assertion = builtins.pathExists cfg.private_key_source;
        # Referencing the path directly, causes the file to be copied to the nix store.
        # By converting the path to a string with toString, we can avoid the file being copied.
        message   = "The private key file at ${toString cfg.private_key_source} does not exist.";
      }
    ];

    nixpkgs.overlays = let
      python_scripts_overlay = self: super: {
        ocb_python_scripts =
          self.callPackage ../scripts/ocb_nixos_python_scripts {};
      };
    in [ python_scripts_overlay ];

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 40;
    };

    swapDevices = mkIf cfg.diskSwap.enable [
      {
        device   = "/swap.img";
        size     = 1024 * cfg.diskSwap.size;
        priority = 0;
        randomEncryption.enable = true;
      }
    ];

    security = {
      sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };
      pam.services.su.forwardXAuth = mkForce false;
    };

    environment = {
      # See https://nixos.org/nix/manual/#ssec-values for documentation on escaping ${
      shellInit = ''
        if [ "''${TERM}" != "screen" ] || [ -z "''${TMUX}" ]; then
          alias nixos-rebuild='printf "Please run nixos-rebuild only from within a tmux session." 2> /dev/null'
        fi
      '';
      shellAliases = {
        nix-env = ''printf "The nix-env command has been disabled. Please use nix-run or nix-shell instead." 2> /dev/null'';
        vi = "vim";
        # Have bash resolve aliases with sudo (https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo)
        sudo = "sudo ";
        whereami = "curl ipinfo.io";
      };
      variables = {
        EDITOR = "vim";
        MSFOCB_SECRETS_DIRECTORY=cfg.secrets.dest_directory;
      };
    };

    users.extraUsers = {
      tunnel = {
        isNormalUser = false;
        isSystemUser = true;
        # The key to connect to the relays will be copied to /run/tunnel
        home         = cfg.private_key_directory;
        createHome   = true;
        shell        = pkgs.nologin;
      };
    };

    # Admins have access to the secrets
    settings.system.secrets.allow_groups = [ "wheel" ];

    system.activationScripts = let
      # Referencing the path directly, causes the file to be copied to the nix store.
      # By converting the path to a string with toString, we can avoid the file being copied.
      private_key_path = if cfg.copy_private_key_to_store
                         then cfg.private_key_source
                         else toString cfg.private_key_source;
    in {
      nix_channel_msf = {
        text = ''
          # We override the root nix channel with the one defined by settings.system.nix_channel
          echo "${cfg.nix_channel} nixos" > "/root/.nix-channels"
        '';
        # We overwrite the value set by the default NixOS activation snippet, that snippet should have run first
        # so that the additional initialisation has been performed.
        # See /run/current-system/activate for the currently defined snippets.
        deps = [ "nix" ];
      };
      tunnel_key_permissions = mkIf (!cfg.isISO) {
        # Use toString, we do not want to change permissions
        # of files in the nix store, only of the source files, if present.
        text = let
          base_files = [ private_key_path cfg.private_key_source_default];
          files = concatStringsSep " " (unique (concatMap (f: [ f "${f}.pub" ]) base_files));
        in ''
          for file in ${files}; do
            if [ -f ''${file} ]; then
              ${pkgs.coreutils}/bin/chown root:root ''${file}
              ${pkgs.coreutils}/bin/chmod 0400 ''${file}
            fi
          done
        '';
        deps = [ "users" ];
      };
      copy_tunnel_key = {
        text = let
          install = source: ''
            ${pkgs.coreutils}/bin/install \
              -o tunnel \
              -g nogroup \
              -m 0400 \
              "${source}" \
              "${cfg.private_key}"
          '';
        in ''
          if [ -f "${private_key_path}" ]; then
            ${install private_key_path}
          elif [ -f "${cfg.private_key_source_default}" ]; then
            ${install cfg.private_key_source_default}
          else
            exit 1;
          fi
        '';
        deps = [ "specialfs" "users" ];
      };
      decrypt_secrets = {
        text = let
          permissions = concatMapStringsSep ","
                                            (group: "group:${group}:rX")
                                            cfg.secrets.allow_groups;
          mkRemoveOldDir = dir: ''
            # Delete the old secrets dir which is not used anymore
            # We maintain it as a link for now for backwards compatibility,
            # so we test first whether it is still a directory
            if [ ! -L "${dir}" ]; then
              ${pkgs.coreutils}/bin/rm --one-file-system \
                                       --recursive \
                                       --force \
                                       "${dir}"
            fi
          '';
        in ''
          echo "decrypting the server secrets..."
          ${concatMapStringsSep "\n" mkRemoveOldDir cfg.secrets.old_dest_directories}
          if [ -e "${cfg.secrets.dest_directory}" ]; then
            ${pkgs.coreutils}/bin/rm --one-file-system \
                                     --recursive \
                                     --force \
                                     "${cfg.secrets.dest_directory}"
          fi
          ${pkgs.coreutils}/bin/mkdir --parent "${cfg.secrets.dest_directory}"

          ${pkgs.ocb_python_scripts}/bin/decrypt_server_secrets \
            --server_name "${config.networking.hostName}" \
            --secrets_path "${cfg.secrets.src_directory}" \
            --output_path "${cfg.secrets.dest_directory}" \
            --private_key_file "${cfg.private_key}"

          # The directory is owned by root
          ${pkgs.coreutils}/bin/chown --recursive root:root "${cfg.secrets.dest_directory}"
          ${pkgs.coreutils}/bin/chmod --recursive u=rwX,g=,o= "${cfg.secrets.dest_directory}"
          # Use an ACL to give access to members of the wheel and docker groups
          ${pkgs.acl}/bin/setfacl --recursive \
                                  --modify ${permissions} \
                                  "${cfg.secrets.dest_directory}"
          echo "decrypted the server secrets"
        '';
        deps = [ "copy_tunnel_key" ];
      };
#      opt_acl = {
#        text = ''
#          # We iterate over all directories that are not hidden.
#          # Prefix directories with a dot to exclude them.
#          for dir in $(ls /opt/); do
#            if [ -d "/opt/''${dir}" ] && \
#               [ ! "containerd" = "''${dir}" ] && \
#               [ ! "lost+found" = "''${dir}" ]; then
#              chown --recursive root:root "/opt/''${dir}"
#              setfacl -R --set "u::rwX,g::r-X,o::---,\
#                                user:root:rwX,\
#                                group:wheel:rwX,\
#                                d:u::rwX,d:g::r-X,d:o::---, \
#                                d:user:root:rwX,\
#                                d:group:wheel:rwX" \
#                                "/opt/''${dir}"
#            fi
#          done
#        '';
#        deps = [ "specialfs" "users" ];
#      };
    };

    systemd = {
      # Given that our systems are headless, emergency mode is useless.
      # We prefer the system to attempt to continue booting so
      # that we can hopefully still access it remotely.
      enableEmergencyMode = false;

      sleep.extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
      '';

      user.services.cleanup_nixenv = {
        enable = true;
        description = "Clean up nix-env";
        unitConfig = {
          ConditionUser  = "!@system";
          ConditionGroup = config.settings.users.shell-user-group;
        };
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.nix}/bin/nix-env -e '.*'
        '';
        wantedBy = [ "default.target" ];
      };
    };

    # No fonts needed on a headless system
    fonts.fontconfig.enable = mkForce false;

    programs = {
      bash.enableCompletion = true;

      ssh = {
        startAgent = false;
        # We do not have GUIs
        setXAuthLocation = false;
        hostKeyAlgorithms = [ "ssh-ed25519" "ssh-rsa" ];
        knownHosts.github = {
          hostNames = [ "github.com" "ssh.github.com" ];
          publicKeyFile = cfg.pub_keys_path + "/servers/github";
        };
        extraConfig = ''
          # Some internet providers block port 22,
          # so we connect to GitHub using port 443
          Host github.com
            HostName ssh.github.com
            User git
            Port 443
        '';
      };

      tmux = {
        enable = true;
        newSession = true;
        clock24 = true;
        historyLimit = 10000;
        extraConfig = ''
          set -g mouse on
        '';
      };
    };

    services = {
      fstrim.enable = true;
      # Avoid pulling in unneeded dependencies
      udisks2.enable = false;

      timesyncd = {
        enable = true;
        servers = mkDefault [
          "0.nixos.pool.ntp.org"
          "1.nixos.pool.ntp.org"
          "2.nixos.pool.ntp.org"
          "3.nixos.pool.ntp.org"
          "time.windows.com"
          "time.google.com"
        ];
      };

      htpdate = {
        enable = true;
        servers = [ "www.kernel.org" "www.google.com" "www.cloudflare.com" ];
      };

      journald = {
        rateLimitBurst = 1000;
        rateLimitInterval = "5s";
        extraConfig = ''
          Storage=persistent
        '';
      };

      # See man logind.conf
      logind = {
        extraConfig = ''
          HandlePowerKey=poweroff
          PowerKeyIgnoreInhibited=yes
        '';
      };

      avahi = {
        enable  = true;
        nssmdns = true;
        extraServiceFiles = {
          ssh = "${pkgs.avahi}/etc/avahi/services/ssh.service";
        };
        publish = {
          enable = true;
          domain = true;
          addresses   = true;
          workstation = true;
        };
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
      cpu.intel.updateMicrocode = true;
      cpu.amd.updateMicrocode   = true;
    };

    documentation = {
      man.enable  = true;
      doc.enable  = false;
      dev.enable  = false;
      info.enable = false;
    };
  };
}

