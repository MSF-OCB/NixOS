{ config, lib, pkgs, ... }:

{
  # The tunnel user being used on relays.
  users.extraUsers.tunnel = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ ../keys/tunnel ];
  };
}
