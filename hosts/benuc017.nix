
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, ... }:

{
  networking.hostName = "benuc017";
  time.timeZone = "Africa/Kinshasa";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/ata-DGM28-A28D81BCBQC-27_20180203AA0016207243";
    };
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = true;
  };

  systemd = with lib; {
    automounts = [
      {
        enable = true;
        description = "Automount the PACS storage directory.";
        where = "/run/pacs";
        wantedBy  = [ "multi-user.target" ];
      }
    ];

    mounts = let
      dependent_services = (optional config.virtualisation.docker.enable "docker.service");
    in [
      {
        enable = true;
        where = "/run/pacs";
        what = "//nestor/PACS";
        type = "cifs";
        options = "rw,credentials=/opt/bahmni_cifs,vers=3,soft,iocharset=utf8,uid=1023,gid=1023,dir_mode=0775,file_mode=0775";
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        before = dependent_services;
        requiredBy = dependent_services;
      }
    ];
  };

}

