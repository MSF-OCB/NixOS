
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  networking.hostName = "benuc004";
  time.timeZone = "Asia/Karachi";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/ata-TS128GMTS600_D130020403";
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6004;
    };
    crypto = {
      enable = false;
      device = "/safe.img";
    };    
    users.users = {
      yusuph.enable = true;
      damien.enable = true;
      didier.enable = true;
      joana.enable  = true;
      kathy.enable  = true;
      godfried.enable = true;
    };
  };

  imports = [
    ../modules/docker.nix
  ];

}

