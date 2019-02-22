{ config, lib, pkgs, ... }:

{
  users.extraUsers.damien = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/damien ];
  };
}
