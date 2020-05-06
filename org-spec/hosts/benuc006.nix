
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################
{ pkgs, ... }:

{
  time.timeZone = "Africa/Johannesburg";

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  settings = {
    network.host_name = "benuc006";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.encrypted_opt = {
      enable = true;
      device = "/safe.img";
    };
    docker.enable = true;
  };

  environment.systemPackages = [ pkgs.certbot ];

  imports = [
    ../../modules/kobofix.nix
  ];
}

