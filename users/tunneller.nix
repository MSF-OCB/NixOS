{ config, lib, pkgs, ... }:

{
  users.extraUsers.tunneller = {
    isNormalUser = true;
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [
      ../keys/didier
      ../keys/dirk
      ../keys/kathy
      ../keys/manu
      ../keys/mohammad
      ../keys/ramses
      ../keys/thierry
      ../keys/yusuph
    ];
  };
}
