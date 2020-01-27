
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, pkgs, ... }:

with lib;

{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 40;
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    pam.services.su.forwardXAuth = mkForce false;
  };
  
  environment = {
    # See https://nixos.org/nix/manual/#ssec-values for documentation on escaping ${
    shellInit = ''
      if [ "''${TERM}" != "screen" ] || [ -z "''${TMUX}" ]; then
        alias nixos-rebuild='printf "Please run nixos-rebuild only from within a tmux session.\c" 2> /dev/null'
      fi
    '';
    shellAliases = {
      vi = "vim";
      # Have bash resolve aliases with sudo (https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo)
      sudo = "sudo ";
      whereami = "curl ipinfo.io";
    };
  };
  
  system.activationScripts = {
    tunnel_key_permissions = ''
      for FILE in "/etc/nixos/local/id_tunnel" "/etc/nixos/local/id_tunnel.pub"; do
        if [ -f ''${FILE} ]; then
          chown root:root ''${FILE}
          chmod 0400 ''${FILE}
        fi
      done
    '';
    settings_link = ''
      SETTINGS_PATH="/etc/nixos/settings.nix"
      if [ $(realpath ''${SETTINGS_PATH}) != "/etc/nixos/hosts/''${HOSTNAME}.nix" ]; then
        ln --force --symbolic hosts/''${HOSTNAME}.nix ''${SETTINGS_PATH}
      fi
    '';
  };

  # No fonts needed on a headless system
  fonts.fontconfig.enable = mkForce false;

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
    fstrim.enable = true;
    # Avoid pulling in unneeded dependencies
    udisks2.enable = false;

    timesyncd = {
      enable = true;
      servers = mkDefault [ 
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
    
    avahi = {
      enable  = true;
      nssmdns = true;
      extraServiceFiles = {
        ssh = "${pkgs.avahi}/etc/avahi/services/ssh.service";
      };
      publish = {
        enable = true;
        domain = true;
        addresses   = true;
        workstation = true;
      };
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    cpu.amd.updateMicrocode   = true;
  };

  documentation = {
    man.enable  = true;
    doc.enable  = false;
    dev.enable  = false;
    info.enable = false;
  };

}

