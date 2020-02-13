
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc015";
  time.timeZone = "Africa/Nord-Kivu";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = true;
    
    autoShutdown = {
      enable = true;
      startAt = "20:00";
    };
    
    users.users = {
      yusuph.enable = true;
      damien.enable = true;
      didier.enable = true;
      pasquale.enable  = true;
      godfried.enable = true;
      vini.enable = true;
    };
  };
}
