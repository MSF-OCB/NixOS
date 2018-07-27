{ config, lib, pkgs, ... }:

{
  users.extraUsers.kathy = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/kathy ];
  };
}

