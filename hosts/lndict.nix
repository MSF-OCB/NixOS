
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  time.timeZone = "Europe/Brussels";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:0:0";
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 7080;
    };
  };

  imports = [
    ../modules/vmware.nix
  ];

  networking = {
    hostName = "lndict";
    interfaces.ens160 = {
      name = "ens160";
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.50.157"; prefixLength = 24; } ];
    };
    defaultGateway = {
      address = "192.168.50.1";
      interface = "ens160";
    };
    nameservers = [ "9.9.9.9" "149.112.112.112" ];
  };

}

