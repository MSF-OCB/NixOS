
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################
{ lib, ... }:

with lib;

{
  settings.users.users = let

    # Admin users have shell access, belong to the wheel group, and are enabled by default
    admin = {
      enable      = true;
      sshAllowed  = true;
      hasShell    = true;
      canTunnel   = true;
      extraGroups = [ "wheel" "docker" ];
    };
    # Users who can tunnel only
    # These are not enabled by default and should be enabled on a by-server basis
    tunnelOnly = {
      enable     = mkDefault false;
      sshAllowed = true;
      hasShell   = false;
      canTunnel  = true;
    };
    # Users who are tunnel-only but can tunnel to all NixOS servers
    tunnelOnlyAllServers = tunnelOnly // { enable = true; };

  in {

    mohammad = admin;
    ramses   = admin;
    thierry  = admin;
    xavier   = admin;
    yves     = admin;

    # Field support team
    #ali      = tunnelOnlyAllServers;
    deepak   = tunnelOnlyAllServers;
    #paul     = tunnelOnlyAllServers;

    # unifield user is a legacy user for Pakistan UF,
    # we cannot easily change the username anymore
    unifield       = tunnelOnly;
    uf_bd_coxcoord = tunnelOnly;
    uf_cd_goma     = tunnelOnly;
    uf_cd_kinshasacoord = tunnelOnly;
    uf_cd_masisi   = tunnelOnly;
    uf_cd_puc      = tunnelOnly;
    uf_ke_embu     = tunnelOnly;
    uf_mz_beira    = tunnelOnly;
    uf_mz_maputo   = tunnelOnly;
    uf_sl_baama    = tunnelOnly;
    uf_sl_kenema   = tunnelOnly;

    # Karachi data encoder, to be migrated to std system for field user keys
    salima   = tunnelOnly;

    damien   = tunnelOnly;
    didier   = tunnelOnly;
    dirk     = tunnelOnly;
    godfried = tunnelOnly;
    joana    = tunnelOnly;
    kathy    = tunnelOnly;
    marco    = tunnelOnly;
    nicolas  = tunnelOnly;
    vini     = tunnelOnly;
    yusuph   = tunnelOnly // {
      hasShell    = true;
      extraGroups = [ "docker" ];
    };

  };

  users.users = {
    # Only user with a password, but not usable via SSH.
    # To be used for console access in case of emergencies.
    msfocb = {
      isNormalUser = true;
      extraGroups  = [ "wheel" ];
      openssh.authorizedKeys.keyFiles = mkForce [];
    };

    # Lock the root user
    root = {
      hashedPassword = mkForce "!";
    };
  };
}

