{ config, lib, ... }:

with lib;

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/amazon-image.nix>
  ];

  ec2.hvm = true;
  settings.boot.mode = "none";
  services.timesyncd.servers = config.networking.timeServers;

  networking.dhcpcd = {
    denyInterfaces  = mkForce [ "veth*" "docker*" ];
    allowInterfaces = mkForce [ "en*" "eth*" ];
  };
}

