
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ./settings.nix
    ./global_settings.nix
    ./maintenance.nix
    ./users.nix
    ./ocb_users.nix
    ./boot.nix
    ./crypto.nix
    ./reverse-tunnel.nix
    ./fail2ban.nix
    ./prometheus.nix
  ];

  networking = {
    # All non-manually configured interfaces are configured by DHCP.
    useDHCP = true;
    dhcpcd = {
      persistent = true;
      # See: https://wiki.archlinux.org/index.php/Dhcpcd#dhcpcd_and_systemd_network_interfaces
      denyInterfaces = [ "eth*" "wlan*" ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      cryptsetup
      keyutils
      wget
      curl
      (import ./vim-config.nix)
      coreutils
      gptfdisk
      file
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
      nmap
      traceroute
      bind
      p7zip
      python3
      nix-info
      nox
    ];
    etc = {
      lustrate = {
        # Can we have this permanently enabled? --> Seems not. Keeping it here for reference.
        # What about /var/lib/docker ?? Other locations that we need to maintain on a working system?
        enable = false;
        target = "NIXOS_LUSTRATE";
        text = ''
          etc/nixos
          opt
          home
        '';
      };
    };
  };

  boot = {

    #kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      # Overwrite free'd memory
      #"page_poison=1"

      # Disable legacy virtual syscalls
      #"vsyscall=none"

      # Disable hibernation (allows replacing the running kernel)
      "nohibernate"
    ];

    kernel.sysctl = {
      # Prevent replacing the running kernel image w/o reboot
      "kernel.kexec_load_disabled" = true;
      
      # Reboot after 10 min following a kernel panic
      "kernel.panic" = "10";

      # Disable bpf() JIT (to eliminate spray attacks)
      #"net.core.bpf_jit_enable" = mkDefault false;

      # ... or at least apply some hardening to it
      "net.core.bpf_jit_harden" = true;

      # Raise ASLR entropy
      "vm.mmap_rnd_bits" = 32;
    };

    # Causes ordering cycle with zramswap, disable until the fix is released
    # https://github.com/NixOS/nixpkgs/pull/52991
    tmpOnTmpfs = false;
  };

  fileSystems."/".options = [ "defaults" "noatime" "acl" ];

  zramSwap = {
    enable = true;
    memoryPercent = 40;
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    pam.services.su.forwardXAuth = lib.mkForce false;
  };

  # No fonts needed on a headless system
  fonts.fontconfig.enable = false;

  programs = {
    bash.enableCompletion = true;

    ssh = {
      startAgent = false;
      # We do not have GUIs
      setXAuthLocation = false;
    };

    tmux = {
      enable = true;
      newSession = true;
      clock24 = true;
      historyLimit = 10000;
      extraTmuxConf = ''
        set -g mouse on
      '';
    };
  };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      forwardX11 = false;
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
      extraConfig = ''
        StrictModes yes
        AllowAgentForwarding no
        TCPKeepAlive yes
        ClientAliveInterval 60
        ClientAliveCountMax 3
        UseDNS no
        GSSAPIAuthentication no
        KerberosAuthentication no
      '';
    };
    
    fstrim.enable = true;

    timesyncd = {
      enable = true;
      servers = [ 
        "172.16.0.101"
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
        "time.windows.com" 
        "time.google.com"
      ];
    };

    htpdate = {
      enable = true;
      servers = [ "www.kernel.org" "www.google.com" "www.cloudflare.com" ];
    };

    journald = {
      rateLimitBurst = 1000;
      rateLimitInterval = "5s";
      extraConfig = ''
        Storage=persistent
      '';
    };

    # See man logind.conf
    logind = {
      extraConfig = ''
        HandlePowerKey=poweroff
        PowerKeyIgnoreInhibited=yes
      '';
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    cpu.amd.updateMicrocode = true;
  };

  users.mutableUsers = false;
  # Lock the root user
  users.extraUsers.root = {
    hashedPassword = "!";
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?

}

