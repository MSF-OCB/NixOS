
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc009";
  time.timeZone = "Africa/Nairobi";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6009;
    };
    crypto = {
      enable = true;
      device = "/safe.img";
    };
    users.users = {
      yusuph.enable   = true;
      damien.enable   = true;
      didier.enable   = true;
      joana.enable    = true;
      kathy.enable    = true;
      pasquale.enable  = true;
      godfried.enable = true;
      vini.enable     = true;
    };
  };

  imports = [
    ../modules/docker.nix
  ];

}

