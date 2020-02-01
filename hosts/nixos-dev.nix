
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ pkgs, ...}:

{

  time.timeZone = "Europe/Brussels";

  settings = {
    boot.mode = "uefi";
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 7030;
    };
    crypto = {
      enable = true;
      device = "/dev/LVMVolGroup_slow/nixos_data";
    };
    vmware.enable = true;
    docker.enable = true;
  };

  environment.systemPackages = with pkgs; [
    ansible
    rsync
  ];

  networking = {
    hostName = "nixos-dev";
    interfaces.ens32 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "172.16.0.75"; prefixLength = 16; } ];
    };
    defaultGateway.address = "172.16.0.100";
  };

}

