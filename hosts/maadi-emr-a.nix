
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  networking.hostName = "maadi-emr-a";
  time.timeZone = "Africa/Cairo";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/wwn-0x5000c50093627fae";
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 7040;
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

