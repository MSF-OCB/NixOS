
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  networking.hostName = "benuc018";
  time.timeZone = "Europe/Kiev";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/wwn-0x502b2a201d1c1b1a";
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6018;
    };
    crypto = {
      enable = true;
      device = "/safe.img";
    };
  };

  imports = [
    ../modules/docker.nix
  ];

}

