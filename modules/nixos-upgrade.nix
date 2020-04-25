{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.autoUpgrade;
in {
  options.system.autoUpgrade.rebootWindow = mkOption {
    description = ''
      Define a lower and upper time value (in HH:MM format) which
      constitute a time window during which reboots are allowed.
    '';
    default = null;
    example = { lower = "01:00"; upper = "05:00"; };
    type = with types; nullOr (submodule {
      options = {
        lower = mkOption {
          description = "Lower limit of the reboot window";
          type = types.strMatching "[[:digit:]]{2}:[[:digit:]]{2}";
          example = "01:00";
        };

        upper = mkOption {
          description = "Upper limit of the reboot window";
          type = types.strMatching "[[:digit:]]{2}:[[:digit:]]{2}";
          example = "05:00";
        };
      };
    });
  };

  config = mkIf cfg.enable (let
    flags = [ "--no-build-output" ] ++
      optionals (cfg.channel != null) [ "-I" "nixpkgs=${cfg.channel}/nixexprs.tar.xz" ];
  in {
    systemd.services.nixos-upgrade = {
      script = let
        nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
        upgradeFlag  = optional (cfg.channel == null) "--upgrade";
        date     = "${pkgs.coreutils}/bin/date";
        readlink = "${pkgs.coreutils}/bin/readlink";
        shutdown = "${pkgs.systemd}/bin/shutdown";
      in mkForce (if cfg.allowReboot then ''
        ${nixos-rebuild} boot ${toString (flags ++ upgradeFlag)}

        booted="$(${readlink} /run/booted-system/{initrd,kernel,kernel-modules})"
        built="$(${readlink} /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"
        ${optionalString (cfg.rebootWindow != null) ''current_time="$(${date} +%H:%M)"''}
 
        if [ "$booted" = "$built" ]; then
          ${nixos-rebuild} switch ${toString flags}
        ${optionalString (cfg.rebootWindow != null) ''
          elif [[ "''${current_time}" < "${cfg.rebootWindow.lower}" ]] || \
               [[ "''${current_time}" > "${cfg.rebootWindow.upper}" ]]; then
            echo "Outside of configured reboot window, skipping."
        ''}
        else
          ${shutdown} -r +1
        fi
      '' else ''
        ${nixos-rebuild} switch ${toString (flags ++ upgradeFlag)}
      '');
    };
  });
}

