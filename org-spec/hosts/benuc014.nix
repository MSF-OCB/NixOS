
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  time.timeZone = "America/Port-au-Prince";

  settings = {
    network.host_name = "benuc014";
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/wwn-0x502b2a201d1c1b1a";
    };
    reverse_tunnel.enable = true;
    crypto.encrypted_opt = {
      enable = true;
      device = "/safe.img";
    };
    docker.enable = true;
  };
}

