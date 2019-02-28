
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, pkgs, lib, ... }:

let
  cfg = config.settings.reverse_tunnel;
in

with lib;

{

  options = {
    settings.reverse_tunnel = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to enable the reverse tunnel services.
        '';
      };

      remote_forward_port = mkOption {
        default = 0;
        type = types.ints.between 0 9999;
        description = ''
          The port on the relay servers.
        '';
      };

      relay = {
        enable = mkOption {
          default = false;
          type = types.bool;
          description = ''
            Whether this server acts as an ssh relay.
          '';
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

  config = mkIf (cfg.enable || cfg.relay.enable) {

    users.extraUsers.tunnel = {
      isNormalUser = false;
      isSystemUser = true;
      # We need the home dir for ssh to store the known_hosts file.
      home = "/home/tunnel";
      createHome = true;
      shell = pkgs.nologin;
      openssh.authorizedKeys.keyFiles = mkIf cfg.relay.enable [ ./keys/tunnel ];
    };

    users.extraUsers.tunneller = mkIf cfg.relay.enable {
      isNormalUser = false;
      isSystemUser = true;
      shell = pkgs.nologin;
      openssh.authorizedKeys.keyFiles = cfg.relay.tunneller.keyFiles;
    };

    environment.etc.id_tunnel = mkIf cfg.enable {
      source = ./local/id_tunnel;
      mode = "0400";
      user = "tunnel";
      group = "tunnel";
    };

    systemd.services = mkIf cfg.enable (let
      reverse_tunnel_config = (import ./global_settings.nix).reverse_tunnel_config;
      make_service = conf: {
        "autossh-reverse-tunnel-${conf.name}" = {
          enable = true;
          description = "AutoSSH reverse tunnel service to ensure resilient ssh access";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            AUTOSSH_GATETIME = "0";
            AUTOSSH_PORT = "0";
          };
          serviceConfig = {
            User = "tunnel";
            Restart = "always";
            RestartSec = 10;
          };
          script = ''
            ${pkgs.autossh}/bin/autossh \
              -q -N \
              -o "ExitOnForwardFailure=yes" \
              -o "ServerAliveInterval=60" \
              -o "ServerAliveCountMax=3" \
              -o "ConnectTimeout=360" \
              -o "UpdateHostKeys=yes" \
              -o "StrictHostKeyChecking=no" \
              -o "IdentitiesOnly=yes" \
              -o "Compression=yes" \
              -o "ControlMaster=no" \
              -R ${toString (conf.port_prefix * 10000 + cfg.remote_forward_port)}:localhost:22 \
              -R ${toString ((3 + conf.port_prefix) * 10000 + cfg.remote_forward_port)}:localhost:9100 \
              -i /etc/id_tunnel \
              tunnel@${conf.host}
          '';
        };
      };
    in
      foldr (conf: services: services // (make_service conf)) {} reverse_tunnel_config);
  };
}

