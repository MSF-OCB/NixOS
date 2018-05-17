{ config, lib, pkgs, ... }:

{
  users.extraUsers.thierry = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ./keys/thierry ];
  };
}

