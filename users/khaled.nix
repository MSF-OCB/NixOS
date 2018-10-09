{ config, lib, pkgs, ... }:

{
  users.extraUsers.khaled = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/khaled ];
  };
}
