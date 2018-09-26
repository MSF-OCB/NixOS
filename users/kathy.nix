{ config, lib, pkgs, ... }:

{
  users.extraUsers.kathy = {
    isNormalUser = true;
    extraGroups = [ ];
    openssh.authorizedKeys.keyFiles = [ ../keys/kathy ];
  };
}

