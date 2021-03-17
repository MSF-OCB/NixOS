{ config, pkgs, lib, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg     = config.settings.reverse_tunnel;
  sys_cfg = config.settings.system;

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

      tunnels = mkOption {
        type    = with types; attrsOf (submodule tunnelOpts);
      };

      relay_servers = mkOption {
        type    = with types; attrsOf (submodule relayServerOpts);
      };

      prometheus_tunnel_port_prefix = mkOption {
        type    = types.ints.between 0 5;
        default = 3;
      };

      relay = {
        enable = mkEnableOption "the relay server functionality";

        ports = mkOption {
          type    = with types; listOf port;
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
    prometheus_enabled = config.settings.services.prometheus.enable;
  in mkIf (cfg.enable || cfg.relay.enable) {

    users.extraUsers = {
      tunnel = let
        stringNotEmpty = s: stringLength s != 0;
        includeTunnel  = tunnel: stringNotEmpty tunnel.public_key && tunnel.remote_forward_port > 0;
        # TODO: remove the true below which is only there for the transition period
        prefixes       = (singleton 0) ++
                         (optional (true || prometheus_enabled) cfg.prometheus_tunnel_port_prefix);
        mkLimitation   = base_port: prefix: "permitlisten=\"${toString (add_port_prefix prefix base_port)}\"";
        mkKeyConfig    = tunnel:
          "${concatMapStringsSep "," (mkLimitation tunnel.remote_forward_port) prefixes} ${tunnel.public_key} tunnel@${tunnel.name}";
        mkKeyConfigs   = msf_lib.compose [ naturalSort
                                           (mapAttrsToList (_: mkKeyConfig))
                                           (filterAttrs (_: includeTunnel)) ];
      in {
        extraGroups = mkIf cfg.relay.enable [ config.settings.users.ssh-group config.settings.users.rev-tunnel-group ];
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
          tunnel_port = cfg.tunnels.${config.networking.hostName}.remote_forward_port;
          prometheus_forward_line = let
            prometheus_port = add_port_prefix cfg.prometheus_tunnel_port_prefix
                                              tunnel_port;
          in optionalString prometheus_enabled
                            ''-R ${toString prometheus_port}:localhost:9100'';
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
                ${prometheus_forward_line} \
                -i ${sys_cfg.private_key} \
                -p ''${port} \
                -l tunnel \
                ''${host}
            done
          done
        '';
      };
      tunnel_services = optionalAttrs cfg.enable (
        mapAttrs' (_: conf: nameValuePair "autossh-reverse-tunnel-${conf.name}"
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

