{ config, lib, pkgs, ... }:

{
  # The tunnel user being used on relays.
  users.extraUsers.tunnel = {
    isNormalUser = false;
    isSystemUser = true;
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ../keys/tunnel ];
  };
}
