{config, pkgs, lib, ...}:

let
  cfg = config.settings.boot;
in

with lib;

{
  options = {
    settings.boot = {
      mode = mkOption {
        type = types.enum [ "legacy" "uefi" ];
        description = ''
          Boot in either legacy or UEFI mode.
        '';
      };

      device = mkOption {
        default = "nodev";
        type = with types; uniq string;
        description = ''
          The device to install GRUB to in legacy mode.
        '';
      };
    };
  };

  config.boot = {
    loader = let
      mode = cfg.mode;
      grub_common = {
        enable = true;
        version = 2;
        memtest86.enable = true;
      };
    in
      if mode == "legacy"
      then {
        grub = grub_common // {
          efiSupport = false;
          device = cfg.device;
        };
      }
      else if mode == "uefi"
      then {
        grub = grub_common // {
          efiSupport = true;
          efiInstallAsRemovable = true;
          device = "nodev";
        };
        efi.efiSysMountPoint = "/boot/efi";
      }
      else
        throw "The settings.boot.mode parameter should be set to either \"legacy\" or \"uefi\"";
  };
}

