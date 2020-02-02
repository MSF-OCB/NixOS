
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc033";
  time.timeZone = "Asia/Kolkata";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = true;
  };

}
