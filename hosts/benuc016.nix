{
  hostname = "benuc016";
  imports = [
    ../crypto.nix
    ../bahmni.nix
  ];

  boot = {
    # Set to either "legacy" or "uefi" depending on how you install the system
    mode = "legacy";
    # Set to "nodev" for an uefi system.
    device = "/dev/disk/by-id/wwn-0x502b2a201d1c1b1a";
  };

  # Timezone of the location where the server will be deployed
  timezone = "Europe/Brussels";
  reverse_tunnel_enabled = true;
  reverse_tunnel_forward_port = "6016";
  crypto.encrypted_device = "/safe.img";

}

