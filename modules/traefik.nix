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

    service_name = mkOption {
      type = types.str;
      default = "nixos-traefik";
      readOnly = true;
    };

    network_name = mkOption {
      type = types.str;
      default = "traefik_backend";
      readOnly = true;
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

  # Options that cannot be defined on the command line, can be defined by
  # creating a YAML file in the Nix store using the nixpkgs builders and
  # by then bind-mounting these configuration files into the Traefik container.
  config = mkIf cfg.enable {
    docker-containers = {
      "${cfg.service_name}" = {
        image = "traefik:${cfg.version}";
        cmd = [
          "--api.insecure=false"
          "--ping"
          "--log.level=INFO"
          "--accesslog=true"
          "--metrics.prometheus=true"
          # We use the Docker provider, but do not expose containers by default
          # A container need to set the correct labels before we forward traffic to it
          "--providers.docker=true"
          "--providers.docker.network=${cfg.network_name}"
          "--providers.docker.exposedbydefault=false"
          # We redirect HTTP to HTTPS
          "--entrypoints.web.address=:80"
          "--entrypoints.web.http.redirections.entrypoint.to=websecure"
          "--entrypoints.web.http.redirections.entrypoint.scheme=https"
          "--entrypoints.web.address=:80"
          "--entrypoints.websecure.address=:443"
          "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
          "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
          # "--certificatesresolvers.letsencrypt.acme.caserver=http://acme-staging-v02.api.letsencrypt.org/directory"
          "--certificatesresolvers.letsencrypt.acme.email=${cfg.acme.email_address}"
          "--certificatesresolvers.letsencrypt.acme.storage=${cfg.acme.storage}/acme.json"
        ];
        ports = [
          "80:80"
          "443:443"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "traefik_letsencrypt:/${cfg.acme.storage}"
        ];
        workdir = "/opt";
        extraDockerOptions = [
          "--network=${cfg.network_name}"
          "--health-cmd=traefik healthcheck --ping"
          "--health-interval=10s"
          "--health-retries=5"
          "--health-timeout=3s"
        ];
      };
    };

    # We add an additional pre-start script to create the Traefik Docker network.
    systemd.services = {
      "docker-${cfg.service_name}" = {
        serviceConfig.ExecStartPre = let
          docker = "${pkgs.docker}/bin/docker";
          script = pkgs.writeShellScript "${cfg.service_name}-create-network" ''
            if [ -z $(${docker} network list --filter "name=^${cfg.network_name}$" --quiet) ]; then
              ${docker} network create ${cfg.network_name}
            fi
          '';
        in [ script ];
      };
    };
  };

}

