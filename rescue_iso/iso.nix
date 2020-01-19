{ config, pkgs, lib, ... }:

with lib;

{

  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ../modules/system.nix
    ../modules/global_settings.nix
    ../modules/packages.nix
    ../modules/sshd.nix
    ../modules/reverse-tunnel.nix
    ../modules/users.nix
    ../modules/ocb_users.nix
  ];

  networking.hostName = "rescue_iso";

  # The live disc overrides SSHd's wantedBy property to an empty value
  # with a priority of 50. We re-override it here.
  # See https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
  systemd.services.sshd.wantedBy = mkOverride 10 [ "multi-user.target" ];

  settings.reverse_tunnel = {
    enable = true;
    prometheus = false;
    remote_forward_port = 8000;
    private_key = ./iso_key/id_tunnel;
  };

  isoImage = {
    isoName = mkForce "${config.isoImage.isoBaseName}-msfocb-rescue-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    appendToMenuLabel = " MSF OCB rescue system";
  };

}
