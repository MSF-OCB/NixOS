{ config, lib, ... }:

with lib;

{

  imports = [
    ./hardware-configuration.nix
    ./settings.nix
    ./modules
    ./modules/auto_shutdown.nix
    ./modules/boot.nix
    ./modules/crypto.nix
    ./modules/docker.nix
    ./modules/maintenance.nix
    ./modules/nfs.nix
    ./modules/panic_button.nix
    ./modules/prometheus.nix
    ./modules/virtualbox.nix
    ./modules/vmware.nix
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

  system.activationScripts = {
    settings_link = let
      hostname         = config.networking.hostName;
      settings_path    = "/etc/nixos/settings.nix";
      destination_path = "/etc/nixos/org-spec/hosts/${hostname}.nix";
    in ''
      if [ -f "${settings_path}" ] && [ ! -L "${settings_path}" ]; then
        rm --force "${settings_path}"
      fi
      if [ ! -f "${settings_path}" ] || \
         [ "$(dirname $(readlink ${settings_path}))" = "hosts" ] || \
         [ "$(realpath ${settings_path})" != "${destination_path}" ]; then
        ln --force --symbolic "${destination_path}" "${settings_path}"
      fi
    '';
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}

