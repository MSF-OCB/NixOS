{ config, lib, pkgs, ... }:

{
  users.extraUsers.mohammad = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/mohammad ];
  };
}

