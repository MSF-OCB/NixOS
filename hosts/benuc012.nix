
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  networking.hostName = "benuc012";
  time.timeZone = "Europe/Brussels";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6012;
    };
    crypto.enable = true;
  };

  imports = [
    ../modules/docker.nix
  ];

}
