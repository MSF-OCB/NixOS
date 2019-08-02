
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  networking.hostName = "sshrelay2";
  time.timeZone = "Europe/Brussels";

  settings = {
    boot.separate_partition = false;
    reverse_tunnel.relay.enable = true;
  };

  imports = [
    ../aws.nix
  ];

}

