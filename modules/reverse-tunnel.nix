{ config, pkgs, lib, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg     = config.settings.reverse_tunnel;
  org_cfg = config.settings.org;

  tunnelOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = msf_lib.host_name_type;
      };

      remote_forward_port = mkOption {
        type = types.ints.between 0 9999;
        description = "The port used for this server on the relay servers.";
      };

      # We allow the empty string to allow bootstrapping an installation where the key has not yet been generated
      public_key = mkOption {
        type = types.either msf_lib.empty_str_type msf_lib.pub_key_type;
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

      addresses = mkOption {
        type = with types; listOf str;
      };

      public_key = mkOption {
        type = msf_lib.pub_key_type;
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

      private_key = mkOption {
        type     = types.str;
        default  = "/run/tunnel/id_tunnel";
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

      tunnels = mkOption {
        type    = with types; attrsOf (submodule tunnelOpts);
        default = {};
      };

      relay_servers = mkOption {
        type    = with types; attrsOf (submodule relayServerOpts);
        default = {};
      };

      prometheus_tunnel_port_prefix = mkOption {
        type    = types.ints.between 0 5;
        default = 3;
      };

      relay = {
        enable = mkEnableOption "the relay server functionality";

        ports = mkOption {
          type    = with types; listOf (ints.between 0 65535);
          default = [ 22 80 443 ];
        };

        tunneller.keyFiles = mkOption {
          type    = with types; listOf path;
          default = [ ];
          description = ''
            The list of key files which are allowed to access the tunneller user to create tunnels.
          '';
        };
      };
    };
  };

  config = let
    add_port_prefix = prefix: base_port: 10000 * prefix + base_port;
  in mkIf (cfg.enable || cfg.relay.enable) {

    assertions = [
      {
        assertion = cfg.enable -> hasAttr config.networking.hostName cfg.tunnels;
        message   = "The reverse tunnel service is enabled but this host's host name is not present in the tunnel config (${toString org_cfg.tunnels_json_path}).";
      }
      {
        assertion = cfg.enable -> builtins.pathExists cfg.private_key_source;
        # Referencing the path directly, causes the file to be copied to the nix store.
        # By converting the path to a string with toString, we can avoid the file being copied.
        message   = "The reverse tunnel key file at ${toString cfg.private_key_source} does not exist.";
      }
    ];

    users.extraUsers = {
      tunnel = let
        stringNotEmpty = s: stringLength s != 0;
        prefixes       = [ 0 cfg.prometheus_tunnel_port_prefix ];
        mkLimitation   = base_port: prefix: "permitlisten=\"${toString (add_port_prefix prefix base_port)}\"";
        mkKeyConfig    = tunnel:
          "${concatMapStringsSep "," (mkLimitation tunnel.remote_forward_port) prefixes} ${tunnel.public_key} tunnel@${tunnel.name}";
        mkKeyConfigs   = msf_lib.compose [ naturalSort
                                           (mapAttrsToList (_: tunnel: mkKeyConfig tunnel))
                                           (filterAttrs (_: tunnel: stringNotEmpty tunnel.public_key)) ];

      in {
        isNormalUser = false;
        isSystemUser = true;
        # The key to connect to the relays will be copied to /run/tunnel
        home         = mkIf (cfg.enable) "/run/tunnel";
        createHome   = mkIf (cfg.enable) true;
        shell        = pkgs.nologin;
        extraGroups  = mkIf cfg.relay.enable [ config.settings.users.ssh-group config.settings.users.rev-tunnel-group ];
        openssh.authorizedKeys.keys = mkIf cfg.relay.enable (mkKeyConfigs cfg.tunnels);
      };

      tunneller = mkIf cfg.relay.enable {
        isNormalUser = false;
        isSystemUser = true;
        shell        = pkgs.nologin;
        # The fwd-tunnel-group is required to be able to proxy through the relay
        extraGroups  = [ config.settings.users.ssh-group config.settings.users.fwd-tunnel-group ];
        openssh.authorizedKeys.keyFiles = cfg.relay.tunneller.keyFiles;
      };
    };

    # This line is very important, it ensures that the remote hosts can
    # set up their reverse tunnels without any issues with host keys
    programs.ssh.knownHosts =
      mapAttrs (_: conf: { hostNames = conf.addresses; publicKey = conf.public_key; })
               cfg.relay_servers;

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
          for file in ${files}; do
            if [ -f ''${file} ]; then
              chown root:root ''${file}
              chmod 0400 ''${file}
            fi
          done
        '';
        deps = [ "users" ];
      };
      copy_tunnel_key = {
        text = let
          install = source: ''install -o tunnel -g nogroup -m 0400 "${source}" "${cfg.private_key}"'';
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
          User       = "tunnel";
          Type       = "simple";
          Restart    = "always";
          RestartSec = "10min";
        };
        script = let
          tunnel_port     = cfg.tunnels."${config.networking.hostName}".remote_forward_port;
          prometheus_port = add_port_prefix cfg.prometheus_tunnel_port_prefix tunnel_port;
        in ''
          for host in ${concatStringsSep " " conf.addresses}; do
            for port in ${concatMapStringsSep " " toString cfg.relay.ports}; do
              echo "Attempting to connect to ''${host} on port ''${port}"
              ${pkgs.autossh}/bin/autossh \
                -T -N \
                -o "ExitOnForwardFailure=yes" \
                -o "ServerAliveInterval=10" \
                -o "ServerAliveCountMax=5" \
                -o "ConnectTimeout=360" \
                -o "UpdateHostKeys=no" \
                -o "StrictHostKeyChecking=yes" \
                -o "UserKnownHostsFile=/dev/null" \
                -o "IdentitiesOnly=yes" \
                -o "Compression=yes" \
                -o "ControlMaster=no" \
                -R ${toString tunnel_port}:localhost:22 \
                -R ${toString prometheus_port}:localhost:9100 \
                -i ${cfg.private_key} \
                -p ''${port} \
                tunnel@"''${host}"
            done
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

