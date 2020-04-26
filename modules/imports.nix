
{ lib, ... }:

with lib;
with (import ../msf_lib.nix);

{
  imports = [
    ../modules/network.nix
    ../modules/packages.nix
    ../modules/load_json.nix
    ../modules/reverse-tunnel.nix
    ../modules/sshd.nix
    ../modules/system.nix
    ../modules/users.nix
    ../org-spec/org.nix
  ];
}

