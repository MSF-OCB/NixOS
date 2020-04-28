{
  time.timeZone = "Africa/Bamenda";

  settings = {
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    network = {
      host_name = "bevm015";
      static_ifaces.enp0s3 = {
        address = "10.210.210.31";
        prefix_length = 24;
        gateway = "10.210.210.254";
      };
    };
  };
}

