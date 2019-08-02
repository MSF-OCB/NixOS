
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, ...}:

let
  cfg = config.settings.boot;
in

with lib;

{
  options = {
    settings.boot = {
      mode = mkOption {
        type = types.enum [ "legacy" "uefi" "none" ];
        description = ''
          Boot in either legacy or UEFI mode.
        '';
      };

      device = mkOption {
        default = "nodev";
        type = types.str;
        description = ''
          The device to install GRUB to in legacy mode.
        '';
      };

      separate_partition = mkOption {
        default = true;
        type = types.bool;
        description = ''
          Whether /boot is a separate partition.
        '';
      };
    };
  };

  config = {
    boot.loader = let
      mode = cfg.mode;
      is_none = (mode == "none");
      grub_common = {
        enable = true;
        version = 2;
        memtest86.enable = true;
      };
    in mkIf (!is_none) (
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
      # This branch is needed because the expr given to mkIf seems to be evaluated eagerly
      else if is_none
      then {}
      else
        throw "The settings.boot.mode parameter should be set to either \"legacy\", \"uefi\" or \"none\""
    );

    fileSystems = mkIf cfg.separate_partition {
      "/boot".options = [ "defaults" "noatime" "nosuid" "nodev" "noexec" ];
    };

  };
}

