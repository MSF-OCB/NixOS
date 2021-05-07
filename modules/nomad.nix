{ config, lib, ... }:

with lib;

let
  cfg = config.settings.services.nomad;
in

{
  # We backport Nomad 1.0 from the nixpkgs master repo
  # until it becomes available in the 21.05 release.
  imports = [ ./nomad/nomad.nix ];

  options.settings.services.nomad = {
    enable = mkEnableOption "the Nomad service";

    datacenter = mkOption {
      type = types.str;
    };

    cluster_size = mkOption {
      type = types.int;
    };
  };

  config = mkIf cfg.enable {
    services.nomad.backported = {
      enable = cfg.enable;
      settings = {
        datacenter = cfg.datacenter;
        server = {
          enabled = true;
          bootstrap_expect = cfg.cluster_size;
        };
      };
    };
  };
}

