########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.settings.nfs;

  nfsCryptoMountOpts = { name, config, ... }: {
    options = {
      enable = mkEnableOption "the crypto mount";

      name = mkOption {
        type = str;
      };

      device = mkOption {
        type = types.str;
      };

      exportTo = mkOption {
        type    = with types; listOf str;
        default = [];
      };
    };

    config = {
      name = mkDefault name;
    };
  };
in
{
  options.settings.nfs = {
    statdPort  = mkOption {
      type     = types.int;
      default  = 4000;
      readOnly = true;
    };
    lockdPort  = mkOption {
      type     = types.int;
      default  = 4001;
      readOnly = true;
    };
    mountdPort = mkOption {
      type     = types.int;
      default  = 4002;
      readOnly = true;
    };
    nfsPorts   = mkOption {
      type     = with types; listOf int;
      default  = [ 111 2049 ];
      readOnly = true;
    };
    nfsExportOptions = mkOption {
      type     = types.str;
      default  = "rw,nohide,secure,no_subtree_check";
      readOnly = true;
    };

    client = {
      enable = mkEnableOption "the NFS client.";
    };
    server = {
      enable = mkEnableOption "the NFS server.";

      cryptoMounts = mkOption {
        type    = with types; attrsOf (submodule nfsCryptoMountOpts);
        default = {};
      };
    };
  };

  config = let
    ports = cfg.nfsPorts ++ [ cfg.statdPort cfg.lockdPort cfg.mountdPort ];
    exported_path = name: "/exports/${name}";

    mkNfsCryptoMount = name: conf: {
      enable             = true;
      device             = conf.device;
      mount_point        = exported_path name;
      mount_options      = "acl,noatime,nosuid,nodev";
      dependent_services = [ "nfs-server.service" ];
    };
    mkNfsCryptoMounts = mapAttrs mkNfsCryptoMount;

    mkClientConf  = client: "${client}(${cfg.nfsExportOptions})";
    mkExportEntry = name: conf: "${exported_path name} ${concatMapStringsSep " " mkClientConf conf.exportTo}";
    mkExports     = confs: concatStringsSep "\n" (mapAttrsToList mkExportEntry confs);

    enabledCryptoMounts = filterAttrs (_: conf: conf.enable) cfg.server.cryptoMounts;
  in mkMerge [
    (mkIf cfg.server.enable {
      settings.crypto.mounts = mkNfsCryptoMounts enabledCryptoMounts;
      services.nfs.server = {
        inherit (cfg) statdPort lockdPort mountdPort;
        enable  = cfg.server.enable;
        exports = mkExports enabledCryptoMounts;
      };
      networking.firewall = {
        allowedTCPPorts = ports;
        allowedUDPPorts = ports;
      };
    })
    (mkIf cfg.client.enable {
      services.rpcbind.enable = cfg.client.enable;
    })
  ];
}

