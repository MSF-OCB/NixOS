
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
    reverse_tunnel.enable = true;
    crypto.encrypted_opt.enable = true;
    vmware = {
      enable = true;
      inDMZ = true;
    };
    docker.enable = true;
    network = {
      host_name = "sherlog-helpdesk";
      static_ifaces.ens192 = {
        address = "192.168.50.154";
        prefix_length = 24;
        gateway = "192.168.50.1";
        fallback = false;
      };
    };
  };
}

