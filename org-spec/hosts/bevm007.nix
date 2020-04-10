{
  time.timeZone = "Africa/Bujumbura";

  settings = {
    network.host_name = "bevm007";
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    crypto.enable = false;
    docker.enable = false;
  };
}