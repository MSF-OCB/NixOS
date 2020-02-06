
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, ...}:

let
  cfg = config.settings.virtualbox;
in

with lib;

{
  options.settings.virtualbox = {
    enable = mkEnableOption "the VirtualBox guest services";
  };

  config = mkIf cfg.enable {
    virtualisation.virtualbox.guest = {
      enable = true;
      x11 = false;
    };
  };
}

