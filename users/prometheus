{ config, lib, pkgs, ... }:

{
  users.extraUsers.prometheus = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/prometheus ];
  };
}
