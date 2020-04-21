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
    network.host_name = "nixos-virt";
    boot.mode = "uefi";
    reverse_tunnel.enable = false;
    crypto.enable = true;
    docker.enable = true;
    virtualbox.enable = true;
    system.nix_channel = "20.03"; 
  };

}

