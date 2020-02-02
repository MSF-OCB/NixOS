
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
    reverse_tunnel.enable = true;
    vmware.enable = true;
    docker.enable = true;
    users.users = {
      yusuph.enable = true;
    };
  };

  networking = {
    hostName = "dhis2-hq-remote";
    interfaces.ens32 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.50.39"; prefixLength = 24; } ];
    };
    defaultGateway.address = "192.168.50.1";
  };
}

