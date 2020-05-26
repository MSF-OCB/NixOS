{ config, lib, ...}:

let
  cfg = config.settings.vmware;
in

with lib;

{
  options.settings.vmware = {
    enable = mkEnableOption "the VMWare guest services";

    inDMZ = mkOption {
      type    = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.vmware.guest = {
      enable   = true;
      headless = true;
    };

    services.timesyncd.servers = mkIf (!cfg.inDMZ) [ "172.16.0.101" ];

    networking.nameservers = if cfg.inDMZ
                             then [ "192.168.50.50" "9.9.9.9" ]
                             else [ "172.16.0.101" "9.9.9.9" ];
  };
}

