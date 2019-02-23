{ config, lib, pkgs, ... }:

{
  users.extraUsers.msfocb = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = (import ../global_settings.nix).admin_user_hashedPassword;
    openssh.authorizedKeys.keyFiles = [];
  };
}

