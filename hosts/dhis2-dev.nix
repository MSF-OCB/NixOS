
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ pkgs, ... }:

{

  time.timeZone = "Europe/Brussels";

  settings = {
    boot = {
      mode = "legacy";
      device = "/dev/disk/by-path/pci-0000:00:10.0-scsi-0:0:0:0";
    };
    reverse_tunnel = {
      enable = true;
      remote_forward_port = 7050;
    };
    
    users.users = {
      xavier.enable = true;
      yusuph.enable = true;
    };
    
    crypto = {
      enable = true;
      device = "/dev/LVMVolGroup/nixos_data";
    };    
  };

  imports = [
    ../vmware.nix
    ../docker-registry.nix
    ../docker.nix
  ];
  
  environment.systemPackages = with pkgs; [
    ansible
    rsync
  ];

  networking = {
    hostName = "dhis2-dev";
    interfaces.ens32 = {
      name = "ens32";
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.50.37"; prefixLength = 24; } ];
    };
    defaultGateway = {
      address = "192.168.50.1";
      interface = "ens32";
    };
    nameservers = [ "172.16.0.101" "8.8.8.8" ];
  };

}

