{ config, lib, pkgs, ... }:

let
  cfg = config.settings.packages;
in

with lib;

{
  options.settings.packages.python_package = mkOption {
    type    = types.package;
    default = pkgs.python3;
  };

  config.environment.systemPackages = with pkgs; [
    cryptsetup
    keyutils
    wget
    curl
    (import ./vim-config.nix)
    coreutils
    gptfdisk
    file
    nfsUtils
    cifs-utils
    htop
    iotop
    lsof
    psmisc
    rsync
    git
    acl
    mkpasswd
    unzip
    lm_sensors
    ipset
    nmap
    tcpdump
    traceroute
    ethtool
    tcptrack
    bind
    dmidecode
    p7zip
    nix-info
    nix-bundle
    # We need python3 to be able to control the machine using Ansible
    cfg.python_package
  ];
}

