
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

  time.timeZone = "Africa/Kinshasa";

  settings = {
    network.host_name = "chk-emr-a";
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-id/wwn-0x5000c500935b35ec";
    };
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = true;

    users.users = {
      "gauthier" = {
        enable      = true;
        sshAllowed  = true;
        hasShell    = true;
        extraGroups = [ "docker" ];
      };
    };
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

