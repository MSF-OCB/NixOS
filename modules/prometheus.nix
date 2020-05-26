{ config, ... }:

{

  settings.users.users.prometheus = {
    enable       = true;
    sshAllowed   = true;
    hasShell     = false;
    canTunnel    = true;
    isSystemUser = true;
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "logind"
      "systemd"
    ];
    # We do not need to open the firewall publicly
    openFirewall = false;
  };

}

