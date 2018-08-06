{ config, lib, pkgs, ... }:

{
  users.extraUsers.didier = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/didier ];
  };
}
