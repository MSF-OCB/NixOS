
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{
  hostname = "benuc010";
  imports = [
  ];

  boot = {
    # Set to either "legacy" or "uefi" depending on how you install the system
    mode = "uefi";
    # Set to "nodev" for an uefi system.
    device = "";
  };

  # Timezone of the location where the server will be deployed
  timezone = "Europe/Brussels";
  reverse_tunnel = {
    enabled = true;
    forward_port = "6010";
  };
  crypto = {
    enabled = true;
    encrypted_device = "/dev/LVMVolGroup/nixos_data";
  };

}

