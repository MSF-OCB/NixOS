{
  hostname = "nixos-dev-xl";
  imports = [
    ../vmware.nix
    ../local/static-network.nix
    ../bahmni.nix
    ../docker-registry.nix
    ../ansible.nix
  ];

  boot = {
    # Set to either "legacy" or "uefi" depending on how you install the system
    mode = "legacy";
    # Set to "nodev" for an uefi system.
    device = "/dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:0:0";
  };

  # Timezone of the location where the server will be deployed
  timezone = "Europe/Brussels";
  reverse_tunnel_enabled = true;
  reverse_tunnel_forward_port = "7030";
  crypto.encrypted_device = "";

}

