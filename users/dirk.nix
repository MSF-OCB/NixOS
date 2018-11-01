{ config, lib, pkgs, ... }:

{
  users.extraUsers.dirk = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/dirk ];
  };
}

