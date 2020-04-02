{
  time.timeZone = "Asia/Dhaka";

  settings = {
    network.host_name = "bevm002";
    boot.mode = "uefi";
    reverse_tunnel.enable = true;
    crypto.enable = false;
    docker.enable = false;
  };
}

