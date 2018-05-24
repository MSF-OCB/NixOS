{ config, lib, pkgs, ... }:

{
  users.extraUsers.msg = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/manu ];
  };
}

