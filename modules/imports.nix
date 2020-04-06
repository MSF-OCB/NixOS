{ lib, ... }:

with lib;
with (import ../msf_lib.nix { inherit lib; });

{
  imports = flatten [
    ../modules/network.nix
    ../modules/packages.nix
    ../modules/load_json.nix
    ../modules/reverse-tunnel.nix
    ../modules/sshd.nix
    ../modules/system.nix
    ../modules/users.nix
    (msf_lib.importIfExists ../org-spec/org.nix)
  ];
}

