{ config, lib, pkgs, ... }:

let
  cfg = config.settings.docker;
in

with lib;

{
  options = {
    settings.docker = {
      enable       = mkEnableOption "the Docker service";
      swarm.enable = mkEnableOption "swarm mode";

      data_dir = mkOption {
        type = types.str;
        default = "/opt/.docker/docker";
        readOnly = true;
      };
    };
  };

  config = mkIf cfg.enable {

    environment = {
      systemPackages = with pkgs; [
        git
        docker_compose
      ];

      # For containers running java, allows to bind mount /etc/timezone
      etc = mkIf (config.time.timeZone != null) {
        timezone.text = config.time.timeZone;
      };
    };

    boot.kernel.sysctl = {
      "vm.overcommit_memory" = 1;
      "net.core.somaxconn" = 65535;
    };

    # Users in the docker group need access to secrets
    settings.system.secrets.allow_groups = [ "docker" ];

    virtualisation.docker = {
      enable       = true;
      enableOnBoot = true;
      liveRestore  = !cfg.swarm.enable;
      extraOptions = concatStringsSep " " (
        # Docker internal IP addressing
        # Ranges used: 172.28.0.0/16, 172.29.0.0/16
        #
        # Docker bridge
        # 172.28.0.1/18
        #   -> 2^14 - 2 (16382) hosts 172.28.0.1 -> 172.28.127.254
        #
        # Custom networks (448 networks in total)
        # 172.28.64.0/18 in /24 blocks
        #   -> 2^6 (64) networks 172.28.64.0/24 -> 172.28.127.0/24
        # 172.28.128.0/17 in /24 blocks
        #   -> 2^7 (128) networks 172.28.128.0/24 -> 172.28.255.0/24
        # 172.29.0.0/16 in /24 blocks
        #   -> 2^8 (256) networks 172.29.0.0/24 -> 172.29.255.0/24
        [
          ''--data-root "${cfg.data_dir}"''
          ''--bip "172.28.0.1/18"''
          ''--default-address-pool "base=172.28.64.0/18,size=24"''
          ''--default-address-pool "base=172.28.128.0/17,size=24"''
          ''--default-address-pool "base=172.29.0.0/16,size=24"''
        ]
      );
    };

    systemd.services = {
      migrate_docker_data_dir = {
        description   = "Migrate the Docker data dir to /opt/.docker";
        before        = [ "docker.service" ];
        wantedBy      = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          if [ -d /opt/docker/ ]; then
            mkdir --parents /opt/.docker/
            mv /opt/docker/ ${cfg.data_dir}
          # old, non-encrypted setups
          elif [ -d /var/lib/docker/ ]; then
            mkdir --parents /opt/.docker/
            mv /var/lib/docker/ ${cfg.data_dir}
          fi
        '';
      };
    };
  };
}

