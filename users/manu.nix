{ config, lib, pkgs, ... }:

{
  users.extraUsers.msg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/manu ];
  };
}

