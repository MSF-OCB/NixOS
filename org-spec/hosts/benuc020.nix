
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
    network.host_name = "benuc020";
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/wwn-0x502b2a201d1c1b1a";
    };
    reverse_tunnel.enable = true;
    crypto = {
      enable = true;
      device = "/safe.img";
    };
    docker.enable = true;
    users.users = {
      unifield.enable   = true;
    };
    
    users.users = {
      "salima" = {
        enable = true;
      };
    };    
  };
}

