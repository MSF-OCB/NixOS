{ config, lib, ...}:

let
  cfg = config.settings.boot;
  nodev = "nodev";
in

with lib;

{
  options = {
    settings.boot = {
      mode = mkOption {
        type = types.enum (attrValues cfg.modes);
        description = "Boot in either legacy or UEFI mode.";
      };

      device = mkOption {
        type    = types.str;
        default = nodev;
        description = "The device to install GRUB to in legacy mode.";
      };

      separate_partition = mkOption {
        type    = types.bool;
        default = true;
        description = "Whether /boot is a separate partition.";
      };

      modes = mkOption {
        type     = with types; attrsOf str;
        default  = { legacy = "legacy"; uefi = "uefi"; none = "none"; };
        readOnly = true;
      };
    };
  };

  config = {

    assertions = [
      {
        assertion = (cfg.mode == cfg.modes.uefi) -> (cfg.device == nodev);
        message   = ''
          For UEFI installations, the boot device (settings.boot.device) should be set to "${nodev}", but I got "${cfg.device}" instead.
        '';
      }
    ];

    boot = {
      growPartition = true;
      cleanTmpDir   = true;
      tmpOnTmpfs    = true;

      loader = let
        inherit (cfg) mode;
        grub_common = {
          enable  = true;
          version = 2;
          inherit (cfg) device;
          memtest86.enable = false;
        };
      in mkIf (mode != cfg.modes.none) (mkMerge [
        (mkIf (mode == cfg.modes.legacy) {
          grub = grub_common // {
            efiSupport = false;
          };
        })
        (mkIf (mode == cfg.modes.uefi) {
          grub = grub_common // {
            efiSupport = true;
            efiInstallAsRemovable = true;
            extraEntries = ''
              menuentry 'Firmware Setup' --class settings {
                fwsetup
                clear
                echo ""
                echo "If you see this message, your EFI system doesn't support this feature."
                echo ""
              }
            '';
          };
          efi.efiSysMountPoint = "/boot/efi";
        })
      ]);

      kernelParams = [
        # Overwrite free'd memory
        #"page_poison=1"

        # Disable legacy virtual syscalls, this can cause issues with older Docker images
        #"vsyscall=none"

        # Disable hibernation (allows replacing the running kernel)
        "nohibernate"
      ];

      kernel.sysctl = {
        # Prevent replacing the running kernel image w/o reboot
        "kernel.kexec_load_disabled" = true;

        # Reboot after 10 min following a kernel panic
        "kernel.panic" = "10";

        # Disable bpf() JIT (to eliminate spray attacks)
        #"net.core.bpf_jit_enable" = mkDefault false;

        # ... or at least apply some hardening to it
        "net.core.bpf_jit_harden" = true;

        # Raise ASLR entropy
        "vm.mmap_rnd_bits" = 32;
      };
    };
  };
}

