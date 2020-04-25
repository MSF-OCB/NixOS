
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.settings.autoShutdown;
in {
  options.settings.autoShutdown = {
    enable = mkEnableOption "the auto-shutdown service";

    startAt = mkOption {
      type    = with types; either str (listOf str);
      default = [];
    };
  };

  config = mkIf cfg.enable {
    systemd.services.auto_shutdown = {
      enable = true;
      description = "Automatically shut down the server at a fixed time.";
      serviceConfig.Type = "oneshot";
      script = ''
        /run/current-system/sw/bin/shutdown -h +5
      '';
      startAt = cfg.startAt;
    };
  };
}

