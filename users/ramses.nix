{ config, lib, pkgs, ... }:

{
  users.extraUsers.ramses = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/ramses ];
  };
}

