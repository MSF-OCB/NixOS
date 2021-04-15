{ config, lib, ...}:

let
  cfg = config.settings.syno_vm;
in

with lib;

{
  options.settings.syno_vm = {
    enable = mkEnableOption "the QEMU guest services for Synology VMs";
  };

  config = mkIf cfg.enable {

    boot.initrd.availableKernelModules = [ "virtio_scsi" ];

    # https://github.com/NixOS/nixpkgs/issues/91300
    virtualisation.hypervGuest.enable = mkForce false;
    services.qemuGuest.enable = true;
  };
}

