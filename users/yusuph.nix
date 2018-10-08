{ config, lib, pkgs, ... }:

{
  users.extraUsers.yusuph = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keyFiles = [ ../keys/yusuph ];
  };
}
