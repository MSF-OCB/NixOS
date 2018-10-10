{ config, lib, pkgs, ... }:

{
  users.extraUsers.joana = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/joana ];
  };
}
