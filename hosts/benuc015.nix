
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
  time.timeZone = "Europe/Brussels";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/wwn-0x502b2a201d1c1b1a";
      separate_partition = false;
    };

    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6015;
    };

    crypto = {
      enable = true;
      device = "/safe.img";
    };

    docker.enable = true;
 
    users.users = {
      yusuph.enable   = true;
      damien.enable   = true;
      didier.enable   = true;
      joana.enable    = true;
      kathy.enable    = true;
      godfried.enable = true;
      vini.enable     = true;
    };
  };
}

