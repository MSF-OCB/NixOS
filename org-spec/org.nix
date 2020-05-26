{ config, lib, ... }:

with lib;

{
  options.settings.org = {
    users_json_path = mkOption {
      type     = types.path;
      default  = ./json/users.json;
      readOnly = true;
    };
    tunnels_json_path = mkOption {
      type     = types.path;
      default  = ./json/tunnels.json;
      readOnly = true;
    };
    keys_path = mkOption {
      type     = types.path;
      default  = ./keys;
      readOnly = true;
    };
  };

  config.settings = {
    system.nix_channel = let
      host_name           = config.settings.network.host_name;
      stable_version      = "20.03";
      upgrade_version     = "20.03";
      early_upgrade_hosts = [];
    in mkDefault (if (elem host_name early_upgrade_hosts)
                  then upgrade_version
                  else stable_version);

    reverse_tunnel.relay_servers = {
      sshrelay1 = {
        addresses  = [ "sshrelay1.msf.be" "185.199.180.11" ];
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0ynb9uL4ZD2qT/azc79uYON73GsHlvdyk8zaLY/gHq";
      };
      sshrelay2 = {
        addresses  = [ "sshrelay2.msf.be" "15.188.17.148"  ];
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDsn2Dvtzm6jJyL9SJY6D1/lRwhFeWR5bQtSSQv6bZYf";
      };
    };
  };
}

