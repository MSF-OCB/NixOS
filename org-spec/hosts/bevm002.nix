{
  time.timeZone = "Asia/Dhaka";

  settings = {
    network.host_name = "bevm002";
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    crypto.enable = false;
    docker.enable = false;
    users.users = {
      uf_bd_coxcoord.enable = true;
    };
  };
}

