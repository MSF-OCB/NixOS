{
  time.timeZone = "Africa/Freetown";

  settings = {
    network.host_name = "bevm004";
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    crypto.enable = false;
    docker.enable = false;
  };
}

