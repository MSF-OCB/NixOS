{
  # The cachix.nix module is automatically generated.
  # See scripts/configure_cachix.sh

  imports = [
    ./cachix.nix
    ./network.nix
    ./packages.nix
    ./load_json.nix
    ./reverse-tunnel.nix
    ./sshd.nix
    ./system.nix
    ./users.nix
    ../org-spec
  ];
}

