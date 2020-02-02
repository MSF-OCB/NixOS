
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc010";
  time.timeZone = "Europe/Brussels";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = true;
  };
}

