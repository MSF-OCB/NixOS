{ config, lib, pkgs, ... }:

{
  users.extraUsers.tunneller = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [
      ../keys/ramses
      ../keys/thierry
      ../keys/manu
      ../keys/dirk
      ../keys/mohammad
      ../keys/kathy
    ];
  };
}
