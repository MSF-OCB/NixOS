{ config, lib, ... }:

with lib;

{
  imports = [
    ./hardware-configuration.nix
    ./settings.nix
    ./modules
  ];

  # We need to force to override the definition in the default AWS config.
  fileSystems = mkForce {
    "/" = {
      device  = "/dev/disk/by-label/nixos_root";
      fsType  = "ext4";
      options = [ "defaults" "noatime" "acl" ];
      autoResize = true;
    };
    "/boot" = mkIf config.settings.boot.separate_partition {
      device  = "/dev/disk/by-label/nixos_boot";
      fsType  = "ext4";
      options = [ "defaults" "noatime" "nosuid" "nodev" "noexec" ];
      autoResize = true;
    };
    "/boot/efi" = mkIf (config.settings.boot.mode == "uefi") {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}

