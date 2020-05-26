{ config, lib, pkgs, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg = config.settings.crypto;

  cryptoOpts = { name, config, ... }: {
    options = {
      enable = mkEnableOption "the encrypted device";

      name = mkOption {
        type = types.strMatching "^[[:lower:]][-_[:lower:]]+[[:lower:]]$";
      };

      device = mkOption {
        type        = types.str;
        example     = "/dev/LVMVolGroup/nixos_data";
        description = "The device to mount.";
      };

      key_file = mkOption {
        type    = types.str;
        default = "/keyfile";
      };

      mount_point = mkOption {
        type        = types.strMatching "^(/[-_[:lower:]]*)+$";
        description = ''
          The mount point on which to mount the partition contained
          in this encrypted volume.
          Currently we assume that every encrypted volume, contains
          a single partition, but this assumption could be generalised.
        '';
      };

      filesystem_type = mkOption {
        type    = types.str;
        default = "ext4";
      };

      mount_options = mkOption {
        type    = types.str;
        default = "";
        example = "acl,noatime,nosuid,nodev";
      };

      dependent_services = mkOption {
        type    = with types; listOf (strMatching "^[-_[:upper:][:lower:]]*\\.service$");
        example = [ "docker.service" "docker-registry.service" ];
        default = [];
      };

    };

    config = {
      name = mkDefault name;
    };
  };
in {

  options.settings.crypto = {
    mounts = mkOption {
      type    = with types; attrsOf (submodule cryptoOpts);
      default = [];
    };

    encrypted_opt = {
      enable = mkEnableOption "the encrypted /opt partition";

      device = mkOption {
        type        = types.str;
        default     = "/dev/LVMVolGroup/nixos_data";
        description = "The device to mount on /opt.";
      };
    };
  };

  imports = [
    (mkRenamedOptionModule [ "settings" "crypto" "enable" ] [ "settings" "crypto" "encrypted_opt" "enable" ])
    (mkRenamedOptionModule [ "settings" "crypto" "device" ] [ "settings" "crypto" "encrypted_opt" "device" ])
  ];

  config = let
    decrypted_name    = conf: "nixos_decrypted_${conf.name}";
    open_service_name = conf: "open_encrypted_${conf.name}";

    mkService = conf: {
      enable      = conf.enable;
      description = "Open the encrypted ${conf.name} partition.";
      conflicts   = [ "shutdown.target" ];
      before      = [ "shutdown.target" ];
      restartIfChanged = false;
      unitConfig = {
        DefaultDependencies = "no";
        ConditionPathExists = "!/dev/mapper/${decrypted_name conf}";
      };
      serviceConfig = {
        User = "root";
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.cryptsetup}/bin/cryptsetup open ${conf.device} ${decrypted_name conf} --key-file ${conf.key_file}
        '';
        ExecStop = ''
          ${pkgs.cryptsetup}/bin/cryptsetup close --deferred ${decrypted_name conf}
        '';
      };
    };
    mkMount = conf: {
      enable = conf.enable;
      #TODO generalise, should we specify the partitions separately?
      what   = "/dev/mapper/${decrypted_name conf}";
      where  = conf.mount_point;
      type   = conf.filesystem_type;
      options    = conf.mount_options;
      after      = [ "${open_service_name conf}.service" ];
      requires   = [ "${open_service_name conf}.service" ];
      wantedBy   = [ "multi-user.target" ];
      before     = conf.dependent_services;
      requiredBy = conf.dependent_services;
    };

    mkServices    = mapAttrs' (_: conf: nameValuePair (open_service_name conf)
                                                      (mkService conf));
    mkMounts      = mapAttrsToList (_: conf: mkMount conf);
  in {
    settings.crypto.mounts = {
      opt = mkIf cfg.encrypted_opt.enable {
        enable = true;
        device = cfg.encrypted_opt.device;
        mount_point   = "/opt";
        mount_options = "acl,noatime,nosuid,nodev";
        # When /opt is a separate partition, it needs to be mounted before starting docker and docker-registry.
        dependent_services = (optional config.virtualisation.docker.enable "docker.service") ++
                             (optional config.services.dockerRegistry.enable "docker-registry.service");
      };
    };
    systemd = let
      enabled = msf_lib.filterEnabled cfg.mounts;
      extra_mount_units = [
        (mkIf cfg.encrypted_opt.enable {
          enable   = true;
          what     = "/opt/.home";
          where    = "/home";
          type     = "none";
          options  = "bind";
          after    = [ "opt.mount" ];
          requires = [ "opt.mount" ];
          wantedBy = [ "multi-user.target" ];
        })
      ];
    in {
      services = mkServices enabled;
      mounts   = mkMounts enabled ++ extra_mount_units;
    };
  };
}

