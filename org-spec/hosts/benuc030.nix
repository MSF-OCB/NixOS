
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  time.timeZone = "Africa/Kinshasa";

  settings = {
    network.host_name = "benuc030";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = true;
  };

}
