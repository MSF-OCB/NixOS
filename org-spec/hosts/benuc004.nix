
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  time.timeZone = "Asia/Karachi";

  settings = {
    network.host_name = "benuc004";
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/ata-TS128GMTS600_D130020403";
    };
    reverse_tunnel.enable = true;
    crypto = {
      enable = false;
      device = "/safe.img";
    };
    docker.enable = true;
    users.users = {
      yusuph.enable = true;
      damien.enable = true;
      didier.enable = true;
      joana.enable  = true;
      kathy.enable  = true;
      godfried.enable = true;
    };
  };

}
