{ config, pkgs, lib, ... }:

with lib;
with (import ../msf_lib.nix);

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
    nfsPorts   = mkOption {
      type     = with types; listOf int;
      default  = [ 111 2049 ];
      readOnly = true;
    };
    nfsUserId  = mkOption {
      type     = types.int;
      default  = 20000;
      readOnly = true;
    };
    nfsExportOptions = mkOption {
      type     = types.str;
      default  = "rw,nohide,secure,no_subtree_check,all_squash,anonuid=${toString cfg.nfsUserId},anongid=65534";
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

    enabledCryptoMounts = msf_lib.filterEnabled cfg.server.cryptoMounts;
  in mkIf cfg.server.enable {
    users.extraUsers.nfs = {
      uid          = cfg.nfsUserId;
      isNormalUser = false;
      isSystemUser = true;
      shell        = pkgs.nologin;
    };
    settings.crypto.mounts = mkNfsCryptoMounts enabledCryptoMounts;
    services.nfs.server = {
      inherit (cfg.server) enable;
      exports = mkExports enabledCryptoMounts;
    };
    networking.firewall = {
      allowedTCPPorts = cfg.nfsPorts;
      allowedUDPPorts = cfg.nfsPorts;
    };
  };
}

