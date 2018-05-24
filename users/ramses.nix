{ config, lib, pkgs, ... }:

{
  users.extraUsers.ramses = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/ramses ];
  };
}

