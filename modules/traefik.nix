{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.settings.services.traefik;
in

{

  options.settings.services.traefik = {
    enable = mkEnableOption "the Traefik service";

    version = mkOption {
      type = types.str;
      default = "2.2";
      readOnly = true;
    };

    image = mkOption {
      type = types.str;
      default = "traefik";
      readOnly = true;
    };

    service_name = mkOption {
      type = types.str;
      default = "nixos-traefik";
      readOnly = true;
    };

    network_name = mkOption {
      type = types.str;
      default = "traefik_backend";
    };

    acme = {
      storage = mkOption {
        type = types.str;
        default = "/letsencrypt";
        readOnly = true;
      };

      email_address = mkOption {
        type = types.str;
        default = "dr.watson@brussels.msf.org";
        readOnly = true;
      };
    };
  };

  config = mkIf cfg.enable {
    docker-containers = let
      static_config_file_name    = "traefik-static.yml";
      static_config_file_target  = "/${static_config_file_name}";
      dynamic_config_file_name   = "traefik-dynamic.yml";
      dynamic_config_file_target = "/${dynamic_config_file_name}";

      static_config_file_source  = pkgs.writeText static_config_file_name ''
        ---

        ping: {}
        log:
          level: INFO
        accesslog: {}
        #metrics:
        #  prometheus: {}

        providers:
          docker:
            network: ${cfg.network_name}
            exposedbydefault: false
          file:
            watch: true
            filename: ${dynamic_config_file_target}

        entryPoints:
          web:
            address: ':80'
            http:
              redirections:
                entryPoint:
                  to: websecure
                  scheme: https
          websecure:
            address: ':443'
            http:
              middlewares:
                - security-headers@file
              tls:
                certResolver: letsencrypt

        certificatesresolvers:
          letsencrypt:
            acme:
              email: ${cfg.acme.email_address}
              storage: ${cfg.acme.storage}/acme.json
              #caserver: http://acme-staging-v02.api.letsencrypt.org/directory
              httpchallenge:
                entrypoint: web
      '';

      dynamic_config_file_source = pkgs.writeText dynamic_config_file_name ''
        ---

        http:
          middlewares:
            security-headers:
              headers:
                sslredirect: true
                stsPreload: true
                stsSeconds: ${toString (365 * 24 * 60 * 60)}
                stsIncludeSubdomains: true

        tls:
          options:
            default:
              minVersion: "VersionTLS12"
              sniStrict: true
              cipherSuites:
                - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
                - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                - "TLS_CHACHA20_POLY1305_SHA256"
                - "TLS_AES_256_GCM_SHA384"
      '';
    in {
      "${cfg.service_name}" = {
        image = "${cfg.image}:${cfg.version}";
        cmd = [
          "--configfile=${static_config_file_target}"
        ];
        ports = [
          "80:80"
          "443:443"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "${static_config_file_source}:${static_config_file_target}:ro"
          "${dynamic_config_file_source}:${dynamic_config_file_target}:ro"
          "traefik_letsencrypt:/${cfg.acme.storage}"
        ];
        workdir = "/opt";
        extraDockerOptions = [
          "--network=${cfg.network_name}"
          "--tmpfs=/tmp:rw,nodev,nosuid,noexec"
          "--tmpfs=/run:rw,nodev,nosuid,noexec"
          "--health-cmd=traefik healthcheck --ping"
          "--health-interval=10s"
          "--health-retries=5"
          "--health-timeout=3s"
        ];
      };
    };

    # We add an additional pre-start script to create the Traefik Docker network.
    systemd.services = let
      docker    = "${pkgs.docker}/bin/docker";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      traefik_docker_service = "docker-${cfg.service_name}";
    in {
      "${traefik_docker_service}" = {
        serviceConfig.ExecStartPre = let
          script = pkgs.writeShellScript "${cfg.service_name}-create-network" ''
            if [ -z $(${docker} network list --filter "name=^${cfg.network_name}$" --quiet) ]; then
              ${docker} network create ${cfg.network_name}
            fi
          '';
        in [ script ];
      };

      #TODO: how can we cleanup old images?
      "${cfg.service_name}-pull" = {
        inherit (cfg) enable;
        description   = "Automatically pull the latest version of the Traefik image";
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${docker} pull ${cfg.image}:${cfg.version}
          ${systemctl} try-restart ${traefik_docker_service}.service
        '';
        startAt = "Wed 03:00";
      };
    };
  };

}

