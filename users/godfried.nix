{ config, lib, pkgs, ... }:

{
  users.extraUsers.godfried = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/godfried ];
  };
}
