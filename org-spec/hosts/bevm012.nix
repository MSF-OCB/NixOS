{
  time.timeZone = "Africa/Bangui";

  settings = {
    network.host_name = "bevm012";
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    system.nix_channel = "20.03";
  };
}
