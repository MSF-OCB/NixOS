
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  time.timeZone = "Africa/Johannesburg";

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  settings = {
    network.host_name = "benuc006";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto = {
      enable = true;
      device = "/safe.img";
    };
    docker.enable = true;
    users.users = {
      unifield.enable   = true;
    };
  };

  imports = [
    ../../modules/kobofix.nix
  ];

}
