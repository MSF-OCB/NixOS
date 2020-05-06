
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  time.timeZone = "Africa/Nairobi";

  settings = {
    network.host_name = "benuc009";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto = {
      encrypted_opt.enable = true;
      device = "/safe.img";
    };
    docker.enable = true;
  };
}

