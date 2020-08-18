{
  # The cachix.nix module is automatically generated.
  # See scripts/configure_cachix.sh

  imports = [
    ./auto_shutdown.nix
    ./boot.nix
    ./cachix.nix
    ./crypto.nix
    ./docker.nix
    ./maintenance.nix
    ./network.nix
    ./nfs.nix
    ./packages.nix
    ./panic_button.nix
    ./prometheus.nix
    ./load_json.nix
    ./reverse-tunnel.nix
    ./sshd.nix
    ./system.nix
    ./traefik.nix
    ./users.nix
    ./virtualbox.nix
    ./vmware.nix
    (if builtins.pathExists ../ocb-config
     then ../ocb-config
     else ../org-spec)
  ];
}

