{ config, lib, ... }:

with lib;

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/amazon-image.nix>
  ];

  ec2.hvm = true;
  settings = {
    boot.mode = "none";
    # For our AWS servers, we do not need to run the upgrade service during
    # the day.
    # Upgrading during the day can cause the nixos_rebuild_config service to
    # refuse to activate the new config due to an upgraded kernel.
    maintenance.nixos_upgrade.startAt = [ "Mon 02:00" ];
  };
  services.timesyncd.servers = config.networking.timeServers;

  networking.dhcpcd = {
    denyInterfaces  = mkForce [ "veth*" "docker*" ];
    allowInterfaces = mkForce [ "en*" "eth*" ];
  };
}

