{ config, pkgs, lib, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg     = config.settings.reverse_tunnel;
  sys_cfg = config.settings.system;

  reverseTunnelOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };
      prefix = mkOption {
        type = types.ints.between 0 5;
        description = ''
          Numerical prefix to be added to the main port.
        '';
      };
      forwarded_port = mkOption {
        type = types.port;
        description = ''
          The local port from this server to forward.
        '';
      };
    };

    config = {
      name = mkDefault name;
    };
  };

  tunnelOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = msf_lib.host_name_type;
      };

      remote_forward_port = mkOption {
        type = with types; either (ints.between 0 0) (ints.between 2000 9999);
        description = "The port used for this server on the relay servers.";
      };

      # We allow the empty string to allow bootstrapping
      # an installation where the key has not yet been generated
      public_key = mkOption {
        type = types.either msf_lib.empty_str_type msf_lib.pub_key_type;
      };

      reverse_tunnels = mkOption {
        type    = with types; attrsOf (submodule reverseTunnelOpts);
        default = {};
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

      ports = mkOption {
        type    = with types; listOf port;
        default = [ 22 80 443 ];
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

      relay = {
        enable = mkEnableOption "the relay server functionality";

        tunneller.keyFiles = mkOption {
          type    = with types; listOf path;
          default = [ ];
          description = "The list of key files which are allowed to access " +
                        "the tunneller user to create tunnels.";
        };
      };
    };
  };

  config = let
    stringNotEmpty = s: stringLength s != 0;
    includeTunnel  = tunnel: stringNotEmpty tunnel.public_key &&
                             tunnel.remote_forward_port > 0;
    add_port_prefix = prefix: base_port: 10000 * prefix + base_port;
    extract_prefix = reverse_tunnel: reverse_tunnel.prefix;
    get_prefixes = mapAttrsToList (_: extract_prefix);

    # Load the config of the host currently being built from the settings
    current_host_tunnel = cfg.tunnels.${config.networking.hostName};
  in mkIf (cfg.enable || cfg.relay.enable) {

    assertions = let
      # Functions to detect duplicate prefixes in our tunnel config
      filter_duplicate_prefixes = prefixes: length prefixes != length (unique prefixes);
      toPrefixes = tunnel: get_prefixes (tunnel.reverse_tunnels);
      pretty_print_prefixes = host: prefixes: let
        int_sort = sort (a: b: a < b);
        sorted_prefixes = concatMapStringsSep ", " toString (int_sort prefixes);
      in "${host}: ${sorted_prefixes}";

      mkDuplicatePrefixes = msf_lib.compose [
        (mapAttrsToList pretty_print_prefixes)       # pretty-print the results
        (filterAttrs (_: filter_duplicate_prefixes)) # get hosts with duplicate prefixes
        (mapAttrs (_: toPrefixes))                   # map tunnels configs to the prefixes
      ];
      duplicate_prefixes = mkDuplicatePrefixes cfg.tunnels;

      # Function to use with foldr,
      # given a tunnel conf and a set mapping ports to booleans,
      # it will add the port to the set with a value of:
      #   - false if the port was not previously there, and
      #   - true  if the port had been added already
      # The result after folding, is a set mapping duplicate ports to true.
      # Port 0 is ignored since it is a placeholder port.
      update_duplicates_set = tunnel: set: let
        port = toString (cfg.tunnels.${tunnel}.remote_forward_port);
        is_duplicate = set: port: port != "0" && hasAttr port set;
      in set // { ${port} = is_duplicate set port; };

      # Use the update_duplicates_set function to calculate
      # a set marking duplicate ports, filter out the duplicates,
      # and return the result as a list of port numbers.
      mkDuplicatePorts = msf_lib.compose [
        attrNames                        # return the name only (=port number)
        (filterAttrs (flip const))       # filter on trueness of the value
        (foldr update_duplicates_set {}) # fold to create the duplicates set
        attrNames                        # convert to a list of tunnel names
      ];
      duplicate_ports = mkDuplicatePorts cfg.tunnels;
    in [
      {
        assertion = length duplicate_prefixes == 0;
        message   = "Duplicate prefixes defined! Details: " +
                    concatStringsSep "; " duplicate_prefixes;
      }
      {
        assertion = length duplicate_ports == 0;
        message   = "Duplicate tunnel ports defined! " +
                    "Duplicates: " +
                    concatStringsSep ", " duplicate_ports;
      }
      {
        assertion = cfg.relay.enable ->
                    hasAttr config.networking.hostName cfg.relay_servers;
        message   = "This host is set as a relay, " +
                    "but its host name could not be found in the list of relays! " +
                    "Defined relays: " +
                    concatStringsSep ", "  (attrNames cfg.relay_servers);
      }
    ];

    users.extraUsers = {
      tunnel = let
        prefixes       = tunnel: get_prefixes tunnel.reverse_tunnels;
        mkLimitation   = base_port: prefix:
          ''permitlisten="${toString (add_port_prefix prefix base_port)}"'';
        mkKeyConfig    = tunnel: concatStringsSep " " [
          (concatMapStringsSep "," (mkLimitation tunnel.remote_forward_port)
                                   (prefixes tunnel))
          tunnel.public_key
          "tunnel@${tunnel.name}"
        ];
        mkKeyConfigs   = msf_lib.compose [ naturalSort
                                           (mapAttrsToList (_: mkKeyConfig))
                                           (filterAttrs (_: includeTunnel)) ];
      in {
        extraGroups = mkIf cfg.relay.enable [ config.settings.users.ssh-group
                                              config.settings.users.rev-tunnel-group ];
        openssh.authorizedKeys.keys = mkIf cfg.relay.enable (mkKeyConfigs cfg.tunnels);
      };

      tunneller = mkIf cfg.relay.enable {
        isNormalUser = false;
        isSystemUser = true;
        shell        = pkgs.nologin;
        # The fwd-tunnel-group is required to be able to proxy through the relay
        extraGroups  = [ config.settings.users.ssh-group
                         config.settings.users.fwd-tunnel-group ];
        openssh.authorizedKeys.keyFiles = cfg.relay.tunneller.keyFiles;
      };
    };

    # This line is very important, it ensures that the remote hosts can
    # set up their reverse tunnels without any issues with host keys
    programs.ssh.knownHosts =
      mapAttrs (_: conf: { hostNames = conf.addresses;
                           publicKey = conf.public_key; })
               cfg.relay_servers;

    systemd.services = let
      make_tunnel_service = tunnel: relay: {
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
          mkRevTunLine = port: rev_tnl: concatStrings [
            "-R "
            (toString (add_port_prefix rev_tnl.prefix port))
            ":localhost:"
            (toString rev_tnl.forwarded_port)
          ];
          mkRevTunLines = port: msf_lib.compose [
            (concatStringsSep " \\\n      ")
            (mapAttrsToList (_: mkRevTunLine port))
          ];
          rev_tun_lines = mkRevTunLines tunnel.remote_forward_port
                                        tunnel.reverse_tunnels;
        in ''
          for host in ${concatStringsSep " " relay.addresses}; do
            for port in ${concatMapStringsSep " " toString relay.ports}; do
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
                ${rev_tun_lines} \
                -i ${sys_cfg.private_key} \
                -p ''${port} \
                -l tunnel \
                ''${host}
            done
          done
        '';
      };
      tunnel_services = optionalAttrs (cfg.enable &&
                                       includeTunnel current_host_tunnel) (
        mapAttrs' (_: relay: nameValuePair "autossh-reverse-tunnel-${relay.name}"
                                           (make_tunnel_service current_host_tunnel
                                                                relay))
                  cfg.relay_servers
      );

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

