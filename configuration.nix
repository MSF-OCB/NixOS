{ config, lib, ... }:

with lib;

let
  root_device = "/dev/disk/by-label/nixos_root";
  boot_device = "/dev/disk/by-label/nixos_boot";
  efi_device  = "/dev/disk/by-label/EFI";

  boot_cfg = config.settings.boot;
  boot_device_enabled = boot_cfg.separate_partition;
  efi_device_enabled  = boot_cfg.mode == boot_cfg.modes.uefi;
in

{
  imports = [
    ./hardware-configuration.nix
    ./settings.nix
    ./modules
  ];

  # Print a warning when the correct labels are not present to avoid
  # an unbootable system.
  warnings = let
    mkWarningMsg = name: path:
      "The ${name} partition is not correctly labelled! " +
      "This installation will probably not boot!\n" +
      "Missing path: ${path}";
    labelCondition = path: ! builtins.pathExists path;
    mkWarning = name: path: enable: optional (enable && labelCondition path)
                                             (mkWarningMsg name path);

    root_warnings = mkWarning "root" root_device true;
    boot_warnings = mkWarning "boot" boot_device boot_device_enabled;
    efi_warnings  = mkWarning "efi"  efi_device  efi_device_enabled;
  in
    root_warnings ++ boot_warnings ++ efi_warnings;

  # We need to force to override the definition in the default AWS config.
  fileSystems = mkForce {
    "/" = {
      device  = root_device;
      fsType  = "ext4";
      options = [ "defaults" "noatime" "acl" ];
      autoResize = true;
    };
    "/boot" = mkIf boot_device_enabled {
      device  = boot_device;
      fsType  = "ext4";
      options = [ "defaults" "noatime" "nosuid" "nodev" "noexec" ];
      autoResize = true;
    };
    "/boot/efi" = mkIf efi_device_enabled {
      device = efi_device;
      fsType = "vfat";
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}

