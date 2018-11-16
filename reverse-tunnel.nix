
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, pkgs, lib, ... }:

{

  # sudo ssh-keygen -a 100 -t ed25519 -N "" -C "tunnel@${HOSTNAME}" -f /etc/nixos/local/id_tunnel

  imports = [
    ./users/tunnel.nix
  ];

  environment.etc.id_tunnel = {
    source = ./local/id_tunnel;
    mode = "0400";
    user = "tunnel";
    group = "tunnel";
  };

  systemd.services = let
    reverse_tunnel_config = [ { name = "google";     host = "msfrelay1.msfict.info";     port_prefix = "";  }
                              { name = "ixelles";    host = "ehealthsshrelayhq1.msf.be"; port_prefix = "";  }
                              { name = "ixelles-ip"; host = "194.78.17.132";             port_prefix = "1"; } ];
    remote_forward_port = (import ./settings.nix).reverse_tunnel_forward_port;
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
          ExecStart = ''${pkgs.autossh}/bin/autossh \
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
            -R ${conf.port_prefix}${remote_forward_port}:localhost:22 \
            -i /etc/id_tunnel \
            tunnel@${conf.host}
          '';
        };
      };
    };
  in
    if (lib.stringLength remote_forward_port) > 4
    then throw "reverse tunnel forward port should be < 9999, found: ${remote_forward_port}"
    else lib.foldr (conf: services: services // (make_service conf)) {} reverse_tunnel_config;

}

