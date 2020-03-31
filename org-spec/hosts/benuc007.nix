
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
    network.host_name = "benuc007";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.enable = false;
    docker.enable = false;
    users.users = {
      uf_mz_beira.enable = true;
    };
  };
}

