
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, pkgs, ... }:

let
  reverse_tunnel = config.settings.reverse_tunnel;
  cfg = config.settings.sshd;
in

with lib;

{
  options = {
    settings = {
      fail2ban.enable = mkOption {
        default = !config.settings.sshguard.enable;
        type = types.bool;
      };
      sshguard.enable = mkOption {
        default = true;
        type = types.bool;
      };
    };
  };

  config = {
    services = {
      openssh = {
        enable = true;
        # Ignore the authorized_keys files in the users' home directories,
        # keys should be added through the config.
        authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
        permitRootLogin = mkDefault "no";
        forwardX11 = false;
        passwordAuthentication = false;
        challengeResponseAuthentication = false;
        allowSFTP = mkIf reverse_tunnel.relay.enable false;
        ports = mkIf reverse_tunnel.relay.enable reverse_tunnel.relay.ports;
        extraConfig = ''
          StrictModes yes
          AllowAgentForwarding no
          TCPKeepAlive yes
          ClientAliveInterval 10
          ClientAliveCountMax 5
          GSSAPIAuthentication no
          KerberosAuthentication no

          AllowGroups wheel ${config.settings.users.ssh-group}

          AllowTcpForwarding no

          Match Group wheel
            AllowTcpForwarding yes

          Match Group ${config.settings.users.fwd-tunnel-group},!wheel
            AllowTcpForwarding local

          ${optionalString reverse_tunnel.relay.enable ''
            Match User tunnel
              AllowTcpForwarding remote
          ''}
        '';
      };

      fail2ban = mkIf config.settings.fail2ban.enable {
        enable = true;
        jails.ssh-iptables = lib.mkForce "";
        jails.ssh-iptables-extra = ''
          action   = iptables-multiport[name=SSH, port="${lib.concatMapStringsSep "," (p: toString p) config.services.openssh.ports}", protocol=tcp]
          maxretry = 3
          findtime = 3600
          bantime  = 3600
          filter   = sshd[mode=extra]
        '';
      };

      sshguard = mkIf config.settings.sshguard.enable {
        enable = true;
        blocktime = 600;
        # 7 * 24 * 60 * 60
        detection_time = 604800;
      };
    };
  };

}

