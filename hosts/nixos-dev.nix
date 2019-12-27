
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
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:0:0";
      separate_partition = false;
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 7030;
    };
    crypto.enable = true;
  };

  imports = [
    ../vmware.nix
    ../docker.nix
    ../docker-registry.nix
  ];
  
  environment.systemPackages = with pkgs; [
    ansible
    rsync
  ];

  networking = {
    hostName = "nixos-dev";
    interfaces.ens192 = {
      name = "ens192";
      useDHCP = false;
      ipv4.addresses = [ { address = "172.16.0.75"; prefixLength = 16; } ];
    };
    defaultGateway = {
      address = "172.16.0.100";
#      interface = "ens192";
    };
    nameservers = [ "172.16.0.101" "8.8.8.8" ];
  };

}

