{ config, lib, pkgs, ... }:

{
  users.extraUsers.thierry = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/thierry ];
  };
}

