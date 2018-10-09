{ config, lib, pkgs, ... }:

{
  users.extraUsers.tunneller = {
    isNormalUser = false;
    isSystemUser = true;
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [
      ../keys/didier
      ../keys/dirk
      ../keys/joana
      ../keys/kathy
      ../keys/manu
      ../keys/mohammad
      ../keys/ramses
      ../keys/thierry
      ../keys/yusuph
      ../keys/khaled
    ];
  };
}
