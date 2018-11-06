{ config, lib, pkgs, ... }:

{
  # The tunnel user being used on relays.
  users.extraUsers.tunnel = {
    isNormalUser = false;
    isSystemUser = true;
    # We need the home dir for ssh to store the known_hosts file.
    home = "/home/tunnel";
    createHome = true;
    shell = pkgs.nologin;
    openssh.authorizedKeys.keyFiles = [ ];
  };
}
