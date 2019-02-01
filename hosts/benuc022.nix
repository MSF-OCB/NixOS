
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  networking.hostName = "benuc022";
  time.timeZone = "Africa/Cairo";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/ata-DGM28-A28D81BCBQC-27_20180223AA1724144410";
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6022;
    };
    crypto = {
      enable = true;
      device = "/dev/LVMVolGroup/nixos_data";
    };
  };

  imports = [
    ../bahmni.nix
  ];

}

