
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
      remote_forward_port = 7051;
    };
    users.users = {
      yusuph.enable = true;
    };
  };

  imports = [
    ../modules/vmware.nix
    ../modules/docker.nix
  ];

  networking = {
    hostName = "dhis2-metadata";
    interfaces.ens32 = {
      name = "ens32";
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.50.38"; prefixLength = 24; } ];
    };
    defaultGateway = {
      address = "192.168.50.1";
      interface = "ens32";
    };
    nameservers = [ "172.16.0.101" "8.8.8.8" ];
  };

}

