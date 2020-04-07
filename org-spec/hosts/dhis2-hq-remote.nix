
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
    network = {
      host_name = "dhis2-hq-remote";
      static_ifaces.ens160 = {
        address = "192.168.50.39";
        prefix_length = 24;
        gateway = "192.168.50.1";
        fallback = false;
      };
    };
  };
}

