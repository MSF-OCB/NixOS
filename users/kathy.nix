{ config, lib, pkgs, ... }:

{
  users.extraUsers.kathy = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/kathy ];
  };
}

