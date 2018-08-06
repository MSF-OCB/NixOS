{ config, lib, pkgs, ... }:

{
  users.extraUsers.yusuph = {
    isNormalUser = true;
    extraGroups = [ ];
    openssh.authorizedKeys.keyFiles = [ ../keys/yusuph ];
  };
}
