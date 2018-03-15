{ config, lib, pkgs, ... }:

{
  users.extraUsers.msg = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keyFiles = [ ./../keys/manu ];
  };
}

