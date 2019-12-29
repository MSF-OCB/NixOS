
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc025";
  time.timeZone = "Africa/Freetown";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/wwn-0x502b2a201d1c1b1a";
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6025;
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

