{ config, pkgs, lib, ... }:

let
  reverse_tunnel = config.settings.reverse_tunnel;
  cfg_users = config.settings.users.users;
  cfg = config.settings.sshd;
in

with lib;

{
  options = {
    settings = {
      fail2ban.enable = mkOption {
        type    = types.bool;
        default = !config.settings.sshguard.enable;
      };
      sshguard.enable = mkOption {
        type    = types.bool;
        default = true;
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
        allowSFTP = true;
        ports = mkIf reverse_tunnel.relay.enable reverse_tunnel.relay.ports;
        kexAlgorithms = [ "curve25519-sha256@libssh.org"
                          "diffie-hellman-group18-sha512"
                          "diffie-hellman-group16-sha512" ];
        macs = [ "hmac-sha2-512-etm@openssh.com"
                 "hmac-sha2-256-etm@openssh.com"
                 "umac-128-etm@openssh.com" ];
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

          Match Group ${config.settings.users.rev-tunnel-group},!wheel
            AllowTcpForwarding remote

          Match Group ${config.settings.users.fwd-tunnel-group},!wheel
            AllowTcpForwarding local

        '' + optionalString reverse_tunnel.relay.enable ''
          Match User ${concatStringsSep "," (attrNames (filterAttrs (_: user: user.enable && user.forceMonitorCommand) cfg_users))}
            PermitTTY no
            ForceCommand ${pkgs.writeShellScript "ssh_port_monitor_command" ''
                             ${pkgs.iproute}/bin/ss -tunl6 | ${pkgs.coreutils}/bin/sort -n | ${pkgs.gnugrep}/bin/egrep "\[::1\]:[0-9]{4}[^0-9]"
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
        # We are a bit more strict on the relays
        attack_threshold = if reverse_tunnel.relay.enable
                           then 40 else 80;
        blocktime = 10 * 60;
        detection_time = 7 * 24 * 60 * 60;
        whitelist = [ "localhost" ];
      };
    };
  };

}

