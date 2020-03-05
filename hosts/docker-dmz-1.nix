
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  time.timeZone = "Europe/Brussels";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel.enable = false;
    crypto.enable = true;
    vmware.enable = true;
    docker.enable = true;
    network = {
      host_name = "docker-dmz-1";
      static_ifaces.ens192 = {
        address = "192.168.50.240";
        prefix_length = 24;
        gateway = "192.168.50.1";
        fallback = false;
      };
    };
  };
}

