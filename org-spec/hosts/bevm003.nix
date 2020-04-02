{
  time.timeZone = "Africa/Kinshasa";

  settings = {
    network.host_name = "bevm003";
    boot.mode = "uefi";
    virtualbox.enable = true;
    reverse_tunnel.enable = true;
    crypto.enable = false;
    docker.enable = false;
    users.users = {
      uf_cd_kinshasacoord.enable = true;
    };
  };
}

