
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc006";
  time.timeZone = "Africa/Johannesburg";

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6006;
    };
    crypto = {
      enable = true;
      device = "/safe.img";
    };
    docker.enable = true;
  };

  imports = [
    ../modules/kobofix.nix
  ];

}
