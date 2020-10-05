{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.settings.services.traefik;
  docker_cfg = config.settings.docker;
in

{

  options.settings.services.traefik = {
    enable = mkEnableOption "the Traefik service";

    version = mkOption {
      type = types.str;
      default = "2.3";
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
      default = "web";
    };

    logging_level = mkOption {
      type = types.enum [ "INFO" "DEBUG" "TRACE" ];
      default = "INFO";
    };

    acme = {
      staging = mkOption {
        type = types.bool;
        default = false;
      };

      keytype = mkOption {
        type = types.str;
        default = "EC256";
        readOnly = true;
      };

      storage = mkOption {
        type = types.str;
        default = "/letsencrypt";
        readOnly = true;
      };

      email_address = mkOption {
        type = types.str;
      };

      dns_provider = mkOption {
        type = types.enum [ "azure" "route53" ];
      };
    };
  };

  config = mkIf cfg.enable {

    settings.docker.enable = true;

    docker-containers = let
      static_config_file_name    = "traefik-static.yml";
      static_config_file_target  = "/${static_config_file_name}";
      dynamic_config_file_name   = "traefik-dynamic.yml";
      dynamic_config_file_target = "/${dynamic_config_file_name}";

      static_config_file_source  = let
        staging_url = "http://acme-staging-v02.api.letsencrypt.org/directory";
        caserver_option = optionalString cfg.acme.staging "caserver: ${staging_url}";
      in pkgs.writeText static_config_file_name ''
        ---

        global:
          sendAnonymousUsage: true

        ping: {}
        log:
          level: ${cfg.logging_level}
        accesslog: {}
        #metrics:
        #  prometheus: {}

        providers:
          docker:
            network: ${cfg.network_name}
            swarmMode: ${if docker_cfg.swarm.enable then "true" else "false"}
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
                - default_middleware@file
              tls:
                certResolver: letsencrypt

        _acme: &acme_cfg
          email: ${cfg.acme.email_address}
          storage: ${cfg.acme.storage}/acme.json
          keyType: ${cfg.acme.keytype}
          ${caserver_option}

        certificatesresolvers:
          letsencrypt:
            acme:
              <<: *acme_cfg
              httpchallenge:
                entrypoint: web
          letsencrypt_dns:
            acme:
              <<: *acme_cfg
              dnschallenge:
                provider: '${cfg.acme.dns_provider}'
      '';

      dynamic_config_file_source = pkgs.writeText dynamic_config_file_name ''
        ---

        http:
          middlewares:
            default_middleware:
              chain:
                middlewares:
                  - security-headers
                  - compress
            security-headers:
              headers:
                sslredirect: true
                stsPreload: true
                stsSeconds: ${toString (365 * 24 * 60 * 60)}
                stsIncludeSubdomains: true
                customResponseHeaders:
                  Expect-CT: "max-age=${toString (24 * 60 * 60)}, enforce"
                  Server: ""
                  X-Powered-By: ""
                  X-AspNet-Version: ""
            compress:
              compress: {}

        tls:
          options:
            default:
              minVersion: "VersionTLS12"
              sniStrict: true
              cipherSuites:
                # https://godoc.org/crypto/tls#pkg-constants
                # TLS 1.2
                - "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
                - "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
                - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
                # TLS 1.3
                - "TLS_AES_256_GCM_SHA384"
                - "TLS_CHACHA20_POLY1305_SHA256"
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
          "--env=LEGO_EXPERIMENTAL_CNAME_SUPPORT=true"
          "--network=${cfg.network_name}"
          "--tmpfs=/tmp:rw,nodev,nosuid,noexec"
          "--tmpfs=/run:rw,nodev,nosuid,noexec"
          "--health-cmd=traefik healthcheck --ping"
          "--health-interval=60s"
          "--health-retries=3"
          "--health-timeout=3s"
        ] ++
        (let
           file = "/opt/.secrets/${cfg.acme.dns_provider}";
         in optional (builtins.pathExists file) "--env-file=${file}");
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

      "${cfg.service_name}-pull" = {
        inherit (cfg) enable;
        description   = "Automatically pull the latest version of the Traefik image";
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${docker} pull ${cfg.image}:${cfg.version}
          ${systemctl} try-restart ${traefik_docker_service}.service
          prev_images="$(${docker} image ls \
            --quiet \
            --filter 'reference=${cfg.image}' \
            --filter 'before=${cfg.image}:${cfg.version}')"
          if [ ! -z "''${prev_images}" ]; then
            ${docker} image rm ''${prev_images}
          fi
        '';
        startAt = "Wed 03:00";
      };
    };
  };
}

