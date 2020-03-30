
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  time.timeZone = "Africa/Maputo";

  settings = {
    network.host_name = "benuc001";
    boot= {
      mode = "legacy";
      device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S2RBNX0HA07507L";
    };
    reverse_tunnel.enable = true;
    crypto = {
      enable = true;
      device = "/safe.img";
    };
    docker.enable = true;
  };
}
