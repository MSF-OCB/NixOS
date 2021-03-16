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

    # For our VMWare servers, we do not need to run the upgrade service during
    # the day.
    # Upgrading during the day can cause the nixos_rebuild_config service to
    # refuse to activate the new config due to an upgraded kernel.
    settings.maintenance.nixos_upgrade.startAt = [ "Mon 02:00" ];

    services.timesyncd.servers = mkIf (!cfg.inDMZ) [ "172.16.0.101" ];

    networking.nameservers = if cfg.inDMZ
                             then [ "192.168.50.50" "9.9.9.9" ]
                             else [ "172.16.0.101" "9.9.9.9" ];
  };
}

