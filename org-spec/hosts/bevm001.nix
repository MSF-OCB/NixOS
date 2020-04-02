{
  time.timeZone = "Africa/Lubumbashi";

  settings = {
    network.host_name = "bevm001";
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    crypto.enable = true;
    docker.enable = false;
  };
}

