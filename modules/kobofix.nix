{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    settings.kobofix.kobo_directory = mkOption {
      default = "/opt/kobo-docker";
      type = types.str;
    };
  };

  config = {
    systemd.services.kobofix = {
      enable = true;
      serviceConfig = {
        User = "root";
        Type = "oneshot";
        WorkingDirectory = config.settings.kobofix.kobo_directory;
      };
      path = [ pkgs.docker ];
      script = let
        docker_compose = "${pkgs.docker_compose}/bin/docker-compose";
      in ''
        #echo "Running rm /tmp/celery* ..."
        #${docker_compose} exec -T kpi sh -c 'rm /tmp/celery*'
        echo "Restarting the containers ..."
        ${docker_compose} down
        ${docker_compose} up -d
      '';
      startAt = "04:05";
    };
  };
}

