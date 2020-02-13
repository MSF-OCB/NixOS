
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.settings.reverse_tunnel;

  tunnelOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };

      remote_forward_port = mkOption {
        type = types.ints.between 0 9999;
        description = "The port used for this server on the relay servers.";
      };

      public_key = mkOption {
        type = types.str;
      };
    };

    config = {
      name = mkDefault name;
    };
  };

  relayServerOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };

      host = mkOption {
        type = types.str;
      };

      ip_tunnel = mkOption {
        type    = types.bool;
        default = false;
      };
    };

    config = {
      name = mkDefault name;
    };
  };
in {

  options = {
    settings.reverse_tunnel = {
      enable = mkEnableOption "the reverse tunnel services";

      private_key_source = mkOption {
        type = types.path;
        default = ../local/id_tunnel;
        description = ''
          The location of the private key file used to establish the reverse tunnels.
        '';
      };

      private_key_source_default = mkOption {
        type = types.str;
        default = "/etc/nixos/local/id_tunnel";
        readOnly = true;
        description = ''
          Hard-coded value of the default location of the private key file,
          used in case the location specified at build time is not available
          at activation time, e.g. when the build was done from within the
          installer with / mounted on /mnt.
          This value is only used in the activation script.
        '';
      };

      private_key = mkOption {
        type = types.str;
        default = "/run/id_tunnel";
        readOnly = true;
        description = ''
          Location to load the private key file for the reverse tunnels from.
        '';
      };

      copy_private_key_to_store = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the private key for the tunnels should be copied to
          the nix store and loaded from there. This should only be used
          when the location where the key is stored, will not be available
          during activation time, e.g. when building an ISO image.
          CAUTION: this means that the private key will be world-readable!
        '';
      };

      tunnels = mkOption {
        type    = with types; attrsOf (submodule tunnelOpts);
        default = [];
      };

      relay_servers = mkOption {
        type = with types; attrsOf (submodule relayServerOpts);
      };

      ip_tunnel_port_prefix = mkOption {
        type = types.ints.between 0 9;
        default = 1;
      };

      prometheus_tunnel_port_prefix = mkOption {
        type = types.ints.between 0 9;
        default = 3;
      };

      relay = {
        enable = mkEnableOption "the relay server functionality";

        ports = mkOption {
          default = [ 22 80 443 ];
          type = with types; listOf (ints.between 0 65535);
        };

        tunneller.keyFiles = mkOption {
          default = [ ];
          type = with types; listOf path;
          description = ''
            The list of key files which are allowed to access the tunneller user to create tunnels.
          '';
        };
      };
    };
  };

  config = let
    add_port_prefix = prefix: base_port: toString (10000 * prefix + base_port);
  in mkIf (cfg.enable || cfg.relay.enable) {

    assertions = [
      {
        assertion = cfg.enable -> hasAttr config.networking.hostName cfg.tunnels;
        message   = "The reverse tunnel service is enabled but this host's host name is not present in the tunnel config (global_settings.nix).";
      }
      {
        assertion = cfg.enable -> builtins.pathExists cfg.private_key_source;
        # Referencing the path directly, causes the file to be copied to the nix store.
        # By converting the path to a string with toString, we can avoid the file being copied.
        message   = "The reverse tunnel key file at ${toString cfg.private_key_source} does not exist.";
      }
    ];

    users.extraUsers.tunnel = let
      prefixes = [ 0 cfg.ip_tunnel_port_prefix cfg.prometheus_tunnel_port_prefix
                   (cfg.ip_tunnel_port_prefix + cfg.prometheus_tunnel_port_prefix) ];
      make_limitation = base_port: prefix: "permitlisten=\"${add_port_prefix prefix base_port}\"";
      make_port_limitations = tunnel:
        "${concatMapStringsSep "," (make_limitation tunnel.remote_forward_port) prefixes} ${tunnel.public_key} tunnel@${tunnel.name}";
    in {
      isNormalUser = false;
      isSystemUser = true;
      shell        = pkgs.nologin;
      extraGroups  = mkIf cfg.relay.enable [ config.settings.users.ssh-group ];
      openssh.authorizedKeys.keys = mkIf cfg.relay.enable (
        naturalSort (mapAttrsToList (_: tunnel: make_port_limitations tunnel) cfg.tunnels));
    };

    users.extraUsers.tunneller = mkIf cfg.relay.enable {
      isNormalUser = false;
      isSystemUser = true;
      shell        = pkgs.nologin;
      # The fwd-tunnel-group is required to be able to proxy through the relay
      extraGroups  = [ config.settings.users.ssh-group config.settings.users.fwd-tunnel-group ];
      openssh.authorizedKeys.keyFiles = cfg.relay.tunneller.keyFiles;
    };

    system.activationScripts = mkIf cfg.enable (let
      # Referencing the path directly, causes the file to be copied to the nix store.
      # By converting the path to a string with toString, we can avoid the file being copied.
      private_key_path = if cfg.copy_private_key_to_store
                         then "${cfg.private_key_source}"
                         else "${toString cfg.private_key_source}";
    in {
      tunnel_key_permissions = {
        # Use toString, we do not want to change permissions
        # of files in the nix store, only of the source files, if present.
        text = let
          base_files = [ private_key_path cfg.private_key_source_default];
          files = concatStringsSep " " (unique (concatMap (f: [ f "${f}.pub" ]) base_files));
        in ''
          for FILE in ${files}; do
            if [ -f ''${FILE} ]; then
              chown root:root ''${FILE}
              chmod 0400 ''${FILE}
            fi
          done
        '';
        deps = [ "users" ];
      };
      copy_tunnel_key = {
        text = let
          install = source: ''install -o tunnel -g root -m 0400 "${source}" "${cfg.private_key}"'';
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
    });

    systemd.services = let
      make_tunnel_service = conf: {
        enable = true;
        description = "AutoSSH reverse tunnel service to ensure resilient ssh access";
        wants = [ "network.target" ];
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          AUTOSSH_GATETIME = "0";
          AUTOSSH_PORT = "0";
          AUTOSSH_MAXSTART = "10";
        };
        serviceConfig = {
          User = "tunnel";
          Restart = "always";
          RestartSec = "10min";
        };
        script = let
          fwd_port = cfg.tunnels."${config.networking.hostName}".remote_forward_port;
          port_prefix = if conf.ip_tunnel then cfg.ip_tunnel_port_prefix else 0;
          tunnel_port = add_port_prefix port_prefix fwd_port;
          prometheus_port = add_port_prefix (cfg.prometheus_tunnel_port_prefix + port_prefix) fwd_port;
        in ''
          for port in ${concatMapStringsSep " " toString cfg.relay.ports}; do
            echo "Attempting to connect to ${conf.host} on port ''${port}"
            ${pkgs.autossh}/bin/autossh \
              -q -T -N \
              -o "ExitOnForwardFailure=yes" \
              -o "ServerAliveInterval=10" \
              -o "ServerAliveCountMax=5" \
              -o "ConnectTimeout=360" \
              -o "UpdateHostKeys=yes" \
              -o "StrictHostKeyChecking=no" \
              -o "GlobalKnownHostsFile=/dev/null" \
              -o "UserKnownHostsFile=/dev/null" \
              -o "IdentitiesOnly=yes" \
              -o "Compression=yes" \
              -o "ControlMaster=no" \
              -R ${tunnel_port}:localhost:22 \
              -R ${prometheus_port}:localhost:9100 \
              -i ${cfg.private_key} \
              -p ''${port} \
              tunnel@${conf.host}
          done
        '';
      };
      tunnel_services = optionalAttrs cfg.enable (
        mapAttrs' (name: conf: nameValuePair ("autossh-reverse-tunnel-${name}")
                                             (make_tunnel_service conf))
                  cfg.relay_servers);

      monitoring_services = optionalAttrs cfg.relay.enable {
        port_monitor = {
          enable = true;
          restartIfChanged = false;
          unitConfig.X-StopOnRemoval = false;
          serviceConfig = {
            User = "root";
            Type = "oneshot";
          };
          script = ''
            ${pkgs.iproute}/bin/ss -Htpln6 | ${pkgs.coreutils}/bin/sort -n
          '';
          # Every 5 min
          startAt = "*:0/5:00";
        };
      };
    in
      tunnel_services // monitoring_services;
  };
}

