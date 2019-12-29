
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  networking.hostName = "benuc031";
  time.timeZone = "Asia/Kabul";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6031;
    };
    crypto.enable = true;
    
    users.users = {
      "msf-kunduz-ehealthsupport" = {
        enable      = true;
        sshAllowed  = true;
        hasShell    = true;
        canTunnel   = true;
        extraGroups = [ "docker" ];
      };
    };
  };

  imports = [
    ../modules/docker.nix
  ];

}
