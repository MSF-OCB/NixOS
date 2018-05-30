{ config, lib, pkgs, ... }:

{
  users.extraUsers.dirk = {
    isNormalUser = true;
    extraGroups = [ ];
    openssh.authorizedKeys.keyFiles = [ ../keys/dirk ];
  };
}

