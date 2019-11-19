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
  cfg = config.settings.crypto;
  addBindMount = c: {
    enable  = c.enable;
    what    = "/opt/${c.name}";
    where   = toString c.source;
    options = "bind";
    before  = c.required_by;
    requiredBy = c.required_by;
    after = [ "opt.mount" ];
    wants = [ "opt.mount" ];
    wantedBy = [ "multi-user.target" ];
  };
in

with lib;

{
  options = {
    settings.crypto = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to try and mount the encrypted data partition.
        '';
      };

      device = mkOption {
        default = "";
        type = types.str;
        description = ''
          The device to mount.
        '';
      };

      bind_mounts = mkOption {
        default = [ ];
        type = with types; listOf (submodule {
          options = {

            enable = mkOption {
              default = true;
              type = types.bool;
            };

            name = mkOption {
              type = types.str;
            };

            source = mkOption {
              type = types.path;
            };

            required_by = mkOption {
              default = [];
              type = with types; listOf str;
            };

          };
        });
      };
    };
  };

  config = {

    systemd = mkIf cfg.enable {
      services.open_nixos_data = {
        enable = cfg.enable;
        description = "Open nixos_data volume";
        conflicts = [ "shutdown.target" ];
        before    = [ "shutdown.target" ];
        unitConfig = {
          DefaultDependencies = "no";
          ConditionPathExists = "!/dev/mapper/nixos_data_decrypted";
        };
        serviceConfig = {
          User = "root";
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''
            ${pkgs.cryptsetup}/bin/cryptsetup open ${cfg.device} nixos_data_decrypted --key-file /keyfile
          '';
          ExecStop = ''
            ${pkgs.cryptsetup}/bin/cryptsetup close nixos_data_decrypted
          '';
        };
      };

      mounts = let
        # When /opt is a separate partition, it needs to be mounted before
        # starting docker and docker-registry.
        # For documentation about "optional" see: https://github.com/NixOS/nixpkgs/blob/master/lib/lists.nix
        dependent_services = (optional config.virtualisation.docker.enable "docker.service") ++
                             (optional config.services.dockerRegistry.enable "docker-registry.service");
      in [

        {
          enable = true;
          what   = "/dev/disk/by-label/nixos_data";
          where  = "/opt";
          type   = "ext4";
          options    = "acl,noatime,nosuid,nodev";
          after      = [ "open_nixos_data.service" ];
          requires   = [ "open_nixos_data.service" ];
          wantedBy   = [ "multi-user.target" ];
          before     = dependent_services;
          requiredBy = dependent_services;
        }

        {
          enable   = true;
          what     = "/opt/.home";
          where    = "/home";
          type     = "none";
          options  = "bind";
          after    = [ "opt.mount" ];
          requires = [ "opt.mount" ];
          wantedBy = [ "multi-user.target" ];
        }

      ] ++ foldr (mount: mounts: mounts ++ [ (addBindMount mount) ]) [] cfg.bind_mounts;

    };

  };

}

