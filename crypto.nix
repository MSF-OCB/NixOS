########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, pkgs, ... }:

{

#  fileSystems = {
#    "/opt" = {
#      label = "nixos_data";
#      fsType = "ext4";
#      encrypted = {
#        enable = false;
#        blkDev = "/dev/LVMVolGroup/nixos_data";
#        keyFile = "/mnt-root/keyfile";
#        label = "nixos_data_decrypted";
#      };
#    };
#
#    "/var/lib/docker" = {
#      device = "/opt/docker";
#      options = [ "bind" ];
#    };
#  };

#  environment.etc = {
#    "crypttab" = {
#      enable = true;
#      text = ''
#        nixos_data_decrypted /dev/LVMVolGroup/nixos_data /keyfile luks
#      '';
#    };
#  };

  systemd = {
    services.open_nixos_data = {
      enable = true;
      description = "Open nixos_data volume";
      after = [ "lvm2-monitor.service" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "lvm2-monitor.service" ];
      unitConfig = {
        ConditionPathExists = "!/dev/mapper/nixos_data_decrypted";
      };
      serviceConfig = {
        User = "root";
        Type = "oneshot";
        ConditionPathExists = "!/dev/mapper/nixos_data_decrypted";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.cryptsetup}/bin/cryptsetup open /dev/LVMVolGroup/nixos_data nixos_data_decrypted --key-file /keyfile
        '';
        ExecStop = ''
          ${pkgs.cryptsetup}/bin/cryptsetup close nixos_data_decrypted
        '';
      };
    };

    mounts = [

      {
        enable = true;
        what = "/dev/disk/by-label/nixos_data";
        where = "/opt";
        type = "ext4";
        options = "acl,noatime,nosuid,nodev,noexec";
        after = [ "open_nixos_data.service" ];
        wants = [ "open_nixos_data.service" ];
        wantedBy = [ "multi-user.target" ];
      }

      {
        enable = true;
        what = "/opt/docker";
        where = "/var/lib/docker";
        options = "bind";
        before = [ "docker.service" ];
        requisite = [ "docker.service" ];
        after = [ "opt.mount" ];
        wants = [ "opt.mount" ];
        wantedBy = [ "multi-user.target" ];
      }

    ];

  };

}
