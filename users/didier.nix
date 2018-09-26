{ config, lib, pkgs, ... }:

{
  users.extraUsers.didier = {
    isNormalUser = false;
    extraGroups = [ ];
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/didier ];
  };
}
