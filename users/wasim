{ config, lib, pkgs, ... }:

{
  # IHS Informatics consultant for Bahmni
  users.extraUsers.wasim = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/ihs_wasim ];
  };
}

