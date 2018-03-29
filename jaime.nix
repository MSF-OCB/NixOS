{ config, lib, pkgs, ... }:

{
  users.extraUsers.jaime = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keyFiles = [ ./keys/jaime ];
  };
}

