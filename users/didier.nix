{ config, lib, pkgs, ... }:

{
  users.extraUsers.didier = {
    isNormalUser = true;
    extraGroups = [ ];
    openssh.authorizedKeys.keyFiles = [ ../keys/didier ];
  };
}
