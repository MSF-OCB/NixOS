{

  services.dockerRegistry = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 5000;
    enableGarbageCollect = true;
    enableDelete = true;
    storagePath = "/opt/docker-registry";
  };
}


