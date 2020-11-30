{ config, lib, pkgs, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg = config.settings.services.traefik;
  system_cfg = config.settings.system;
  docker_cfg = config.settings.docker;

  # The compat version can be removed when all servers are on 20.09.
  traefik_config_format = (pkgs.formats.yaml or msf_lib.formats.compat.yaml) {};
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

    dynamic_config = mkOption {
      type = with types; attrsOf (submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
          };
          value = mkOption {
            type = traefik_config_format.type;
          };
        };
      });
    };

    network_name = mkOption {
      type = types.str;
      default = "web";
    };

    logging_level = mkOption {
      type = types.enum [ "INFO" "DEBUG" "TRACE" ];
      default = "INFO";
    };

    accesslog = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };

    pilot_token = mkOption {
      type = types.str;
    };

    traefik_entrypoint_port = mkOption {
      type = types.port;
      default = 8080;
    };

    content_type_nosniff_enable = mkOption {
      type = types.bool;
      default = true;
    };

    acme = {
      staging = {
        enable = mkEnableOption "the Let's Encrypt staging environment";

        caserver = mkOption {
          type = types.str;
          default = "http://acme-staging-v02.api.letsencrypt.org/directory";
          readOnly = true;
        };
      };

      crossSignedChain = {
        enable = mkEnableOption "the Let's Encrypt cross-signed certificate chain";

        preferredChain = mkOption {
          type = types.str;
          default = "DST Root CA X3";
          readOnly = true;
          description = ''
            The Common Name (CN) of the root certificate to anchor the chain on.
          '';
        };
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

  config = let
    security-headers       = "security-headers";
    hsts-headers           = "hsts-headers";
    compress-middleware    = "compress-middleware";
    default-middleware     = "default-middleware";
    default-ssl-middleware = "default-ssl-middleware";
  in mkIf cfg.enable {

    settings = {
      docker.enable = true;

      services.traefik = {
        acme.crossSignedChain.enable = true;

        dynamic_config.default_config = {
          enable = true;
          value = {
            http = {
              routers.dashboard = {
                entryPoints = [ "traefik" ];
                rule = "PathPrefix(`/api`) || PathPrefix(`/dashboard`)";
                service = "api@internal";
              };

              middlewares = {
                ${default-ssl-middleware}.chain.middlewares = [
                  "${hsts-headers}@file"
                  "${default-middleware}@file"
                ];
                ${default-middleware}.chain.middlewares = [
                  "${security-headers}@file"
                  "${compress-middleware}@file"
                ];
                ${security-headers}.headers = {
                  contentTypeNosniff = mkIf cfg.content_type_nosniff_enable true;
                  browserXssFilter = true;
                  referrerPolicy = "no-referrer, strict-origin-when-cross-origin";
                  customFrameOptionsValue = "SAMEORIGIN";
                  customResponseHeaders = {
                    Expect-CT = "max-age=${toString (24 * 60 * 60)}, enforce";
                    Server = "";
                    X-Generator = "";
                    X-Powered-By = "";
                    X-AspNet-Version = "";
                  };
                };
                ${hsts-headers}.headers = {
                  sslredirect = true;
                  stsPreload = true;
                  stsSeconds = toString (365 * 24 * 60 * 60);
                  stsIncludeSubdomains = true;
                };
                ${compress-middleware}.compress = {};
              };
            };

            tls.options.default = {
              minVersion = "VersionTLS12";
              sniStrict = true;
              cipherSuites = [
                # https://godoc.org/crypto/tls#pkg-constants
                # TLS 1.2
                "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
                "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
                # TLS 1.3
                "TLS_AES_256_GCM_SHA384"
                "TLS_CHACHA20_POLY1305_SHA256"
              ];
            };
          };
        };
      };
    };

    docker-containers = let
      static_config_file_name   = "traefik-static.yml";
      static_config_file_target = "/${static_config_file_name}";
      dynamic_config_directory_name   = "traefik-dynamic.conf.d";
      dynamic_config_directory_target = "/${dynamic_config_directory_name}";

      static_config_file_source = let
        letsencrypt = "letsencrypt";
        caserver       = optionalAttrs cfg.acme.staging.enable
                                       { inherit (cfg.acme.staging) caserver; };
        preferredChain = optionalAttrs cfg.acme.crossSignedChain.enable
                                       { inherit (cfg.acme.crossSignedChain) preferredChain; };
        acme_template = {
          email = cfg.acme.email_address;
          storage = "${cfg.acme.storage}/acme.json";
          keyType = cfg.acme.keytype;
        } // caserver
          // preferredChain;
        accesslog = optionalAttrs cfg.accesslog.enable {
          accessLog = {
            # Make sure that the times are printed in local time
            # https://doc.traefik.io/traefik/observability/access-logs/#time-zones
            fields.names.StartUTC = "drop";
          };
        };
        static_config = {
          global.sendAnonymousUsage = true;
          pilot.token = cfg.pilot_token;
          ping = {};
          log.level = cfg.logging_level;
          api.dashboard = true;
          #metrics:
          #  prometheus: {}

          providers = {
            docker = {
              network = cfg.network_name;
              swarmMode = docker_cfg.swarm.enable;
              exposedbydefault = false;
            };
            file = {
              watch = true;
              directory = dynamic_config_directory_target;
            };
          };

          entryPoints = {
            web = {
              address = ":80";
              http = {
                redirections.entryPoint = {
                  to = "websecure";
                  scheme = "https";
                };
                middlewares = [ "${default-middleware}@file" ];
              };
            };
            websecure = {
              address = ":443";
              http = {
                middlewares = [ "${default-ssl-middleware}@file" ];
                tls.certResolver = letsencrypt;
              };
            };
            traefik = {
              address = ":${toString cfg.traefik_entrypoint_port}";
              http.middlewares = [ "${default-middleware}@file" ];
            };
          };

          certificatesresolvers = {
            ${letsencrypt}.acme =
              acme_template // {
                httpChallenge.entryPoint = "web";
              };
            "${letsencrypt}_dns".acme =
              acme_template // {
                dnsChallenge = {
                  resolvers = [
                    "9.9.9.9:53"
                    "8.8.8.8:53"
                    "1.1.1.1:53"
                  ];
                  provider = cfg.acme.dns_provider;
                };
              };
          };
        } // accesslog;
      in traefik_config_format.generate static_config_file_name static_config;

      dynamic_config_mounts = let
        buildConfigFile = key: configFile: let
          name = "${key}.yml";
          file = traefik_config_format.generate name configFile.value;
        in "${file}:${dynamic_config_directory_target}/${name}:ro";
        buildConfigFiles = mapAttrsToList buildConfigFile;
      in msf_lib.compose [
           buildConfigFiles
           msf_lib.filterEnabled
         ] cfg.dynamic_config;

      dns_credentials_file_option = let
        file = system_cfg.secretsDirectory + cfg.acme.dns_provider;
      in optional (builtins.pathExists file) "--env-file=${file}";

    in {
      "${cfg.service_name}" = {
        image = "${cfg.image}:${cfg.version}";
        cmd = [
          "--configfile=${static_config_file_target}"
        ];
        ports = let
          traefik_entrypoint_port_str = toString cfg.traefik_entrypoint_port;
        in [
          "80:80"
          "443:443"
          "127.0.0.1:${traefik_entrypoint_port_str}:${traefik_entrypoint_port_str}"
          "[::1]:${traefik_entrypoint_port_str}:${traefik_entrypoint_port_str}"
        ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "${static_config_file_source}:${static_config_file_target}:ro"
          "traefik_letsencrypt:${cfg.acme.storage}"
        ] ++ dynamic_config_mounts;
        workdir = "/";
        extraDockerOptions = [
          "--env=LEGO_EXPERIMENTAL_CNAME_SUPPORT=true"
          "--network=${cfg.network_name}"
          "--tmpfs=/tmp:rw,nodev,nosuid,noexec"
          "--tmpfs=/run:rw,nodev,nosuid,noexec"
          "--health-cmd=traefik healthcheck --ping"
          "--health-interval=60s"
          "--health-retries=3"
          "--health-timeout=3s"
        ] ++ dns_credentials_file_option;
      };
    };

    # We define an additional service to create the Traefik Docker network.
    systemd.services = let
      docker    = "${pkgs.docker}/bin/docker";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      traefik_docker_service_name = "docker-${cfg.service_name}";
      traefik_docker_service = "${traefik_docker_service_name}.service";
    in {
      docker-nixos-traefik-create-network = {
        inherit (cfg) enable;
        description = "Create the network for Traefik.";
        before      = [ traefik_docker_service ];
        requiredBy  = [ traefik_docker_service ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          if [ -z $(${docker} network list --filter "name=^${cfg.network_name}$" --quiet) ]; then
            ${docker} network create ${cfg.network_name}
          fi
        '';
      };

      # Restore the defaults to have proper logging in the systemd journal.
      # See GitHub NixOS/nixpkgs issue #102768 and PR #102769
      "${traefik_docker_service_name}" = {
        serviceConfig = {
          StandardOutput = mkForce "journal";
          StandardError  = mkForce "inherit";
        };
      };

      "${cfg.service_name}-pull" = {
        inherit (cfg) enable;
        description   = "Automatically pull the latest version of the Traefik image";
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${docker} pull ${cfg.image}:${cfg.version}
          ${systemctl} try-restart ${traefik_docker_service}
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

