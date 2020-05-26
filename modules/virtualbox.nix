{ config, lib, ...}:

let
  cfg = config.settings.virtualbox;
in

with lib;

{
  options.settings.virtualbox = {
    enable = mkEnableOption "the VirtualBox guest services";
  };

  config = mkIf cfg.enable {
    virtualisation.virtualbox.guest = {
      enable = true;
      x11 = false;
    };

    # https://github.com/NixOS/nixpkgs/issues/76980
    boot.initrd.availableKernelModules = [ "virtio_scsi" ];
  };
}

