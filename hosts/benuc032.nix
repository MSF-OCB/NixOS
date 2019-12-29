
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ pkgs, ...}:

{
  networking.hostName = "benuc032";
  time.timeZone = "Asia/Kabul";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6032;
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
  
  environment.systemPackages = with pkgs; [
    ansible
    rsync
  ];

}
