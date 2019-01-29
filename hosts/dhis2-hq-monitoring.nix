
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  hostname = "dhis2-hq-monitoring";
  imports = [
    ../vmware.nix
    ../local/static-network.nix
    ../bahmni.nix
    ../docker-registry.nix
    ../docker.nix
    ../ansible.nix
  ];

  boot = {
    # Set to either "legacy" or "uefi" depending on how you install the system
    mode = "legacy";
    # Set to "nodev" for an uefi system.
    device = "/dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:0:0";
  };

  # Timezone of the location where the server will be deployed
  timezone = "Europe/Brussels";
  reverse_tunnel = {
    enabled = true;
    forward_port = "7053";
  };
  crypto = {
    enabled = false;
    encrypted_device = "";
  };

}
