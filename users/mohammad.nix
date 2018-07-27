{ config, lib, pkgs, ... }:

{
  users.extraUsers.mohammad = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/mohammad ];
  };
}

