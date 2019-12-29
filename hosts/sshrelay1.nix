
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
    reverse_tunnel.relay.enable = true;
  };

  imports = [
    ../modules/vmware.nix
  ];

  networking = {
    hostName = "sshrelay1";
    interfaces.ens160 = {
      name = "ens160";
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.50.143"; prefixLength = 24; } ];
    };
    defaultGateway = {
      address = "192.168.50.1";
      interface = "ens160";
    };
    nameservers = [ "8.8.4.4" "8.8.8.8" ];
  };

}
