
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  time.timeZone = "Africa/Cairo";

  settings = {
    network.host_name = "benuc022";
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/ata-DGM28-A28D81BCBQC-27_20180223AA1724144410";
    };
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = true;
  };

}

