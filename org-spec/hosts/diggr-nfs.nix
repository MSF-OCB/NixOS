########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ lib, ... }:

with lib;

{
  time.timeZone = "Europe/Brussels";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    nfs.server = {
      enable = true;
      cryptoMounts = let
        exportTo = [ "docker-dmz-11.ocb.msf.org" ];
      in {
        esdata = {
          enable = true;
          device = "/dev/LVM_FCdata3_VG/esdata";
          inherit exportTo;
        };
        esproxy = {
          enable = true;
          device = "/dev/LVM_FCdata1_VG/esproxy";
          inherit exportTo;
        };
        esbackup = {
          enable = true;
          device = "/dev/LVM_NLdata1_VG/esbackup";
          inherit exportTo;
        };
        diggr_other = {
          enable = true;
          device = "/dev/LVM_FCdata2_VG/diggr_other";
          inherit exportTo;
        };
      };
    };
    vmware.enable = true;
    network = {
      host_name = "diggr-nfs";
      static_ifaces.ens192 = {
        address = "172.16.0.95";
        prefix_length = 22;
        gateway = "172.16.0.100";
        fallback = false;
      };
    };
  };
}
