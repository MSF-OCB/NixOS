
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  time.timeZone = "Africa/Maputo";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 6016;
    };
    crypto = {
      enable = true;
      device = "/dev/LVMVolGroup/nixos_data";
    };
  };

  imports = [
    ../docker.nix
    ../kobofix.nix
  ];
  
  networking = {
    hostName = "benuc016";

    interfaces.enp3s0 = {
      name = "enp3s0";
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.123.151"; prefixLength = 24; } ];
    };
    defaultGateway = {
      address = "192.168.123.254";
      interface = "enp3s0";
    };
    nameservers = [ "1.1.1.1" "1.0.0.1" ];

    #For kobo & let's encrypt
    firewall.allowedTCPPorts = [ 80 443 ];
  };

}

