{ config, pkgs, lib, ... }:

let
  reverse_tunnel = config.settings.reverse_tunnel;
  cfg_users = config.settings.users.users;
  cfg = config.settings.sshd;
in

with lib;
with (import ../msf_lib.nix);

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
      openssh = let
        # We define a function to build the Match section defining the
        # configured ForceCommand settings.
        buildForceCommandSection = let
          hasForceCommand    = _: user: user.enable && ! (isNull user.forceCommand);
          filterForceCommand = filterAttrs hasForceCommand;
          # unsafeDiscardStringContext is needed such that Nix allows us
          # to use a string derived from a store path without tracking
          # the dependency. This is safe in this case because we will
          # reference the original string later on in the SSHd config file.
          hashCommand    = msf_lib.compose [ (builtins.hashString "sha256")
                                             (builtins.unsafeDiscardStringContext) ];
          cleanResults   = mapAttrs (_: users: { inherit (builtins.head users) forceCommand;
                                                 users = map (user: user.name) users;
                                               });
          doGroupByCommand = groupBy (user: hashCommand user.forceCommand);
          groupByCommand   = msf_lib.compose [ cleanResults doGroupByCommand attrValues ];

          toCfgs = mapAttrsToList (_: res: ''
                     Match User ${concatStringsSep "," res.users}
                     PermitTTY no
                     ForceCommand ${pkgs.writeShellScript "ssh_force_command" res.forceCommand}
                   '');
          toCfg = concatStringsSep "\n";

        in msf_lib.compose [ toCfg
                             toCfgs
                             groupByCommand
                             filterForceCommand ];
      in {
        enable = true;
        # Ignore the authorized_keys files in the users' home directories,
        # keys should be added through the config.
        authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
        permitRootLogin = mkDefault "no";
        forwardX11 = false;
        passwordAuthentication = false;
        challengeResponseAuthentication = false;
        allowSFTP = true;
        ports = let
          host_name   = config.networking.hostName;
          relay_ports = reverse_tunnel.relay_servers.${host_name}.ports;
        in mkIf reverse_tunnel.relay.enable relay_ports;
        kexAlgorithms = [ "curve25519-sha256@libssh.org"
                          "diffie-hellman-group18-sha512"
                          "diffie-hellman-group16-sha512" ];
        ciphers = [ "aes256-gcm@openssh.com"
                    "chacha20-poly1305@openssh.com" ];
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

          ${buildForceCommandSection cfg_users}
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

