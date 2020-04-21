{
  time.timeZone = "America/Caracas";

  settings = {
    network.host_name = "bevm013";
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    system.nix_channel = "20.03";
  };
}
