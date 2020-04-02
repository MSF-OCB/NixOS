{
  time.timeZone = "Asia/Dhaka";

  settings = {
    network.host_name = "bevm002";
    boot.mode = "uefi";
    reverse_tunnel.enable = false;
    crypto.enable = true;
    docker.enable = false;
  };
}

