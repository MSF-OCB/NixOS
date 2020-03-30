
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  settings.users.users = let

    admin = {
      enable      = true;
      sshAllowed  = true;
      hasShell    = true;
      canTunnel   = true;
      extraGroups = [ "wheel" "docker" ];
    };
    tunnelOnly = {
      sshAllowed = true;
      hasShell   = false;
      canTunnel  = true;
    };

  in {

    mohammad = admin;
    ramses   = admin;
    thierry  = admin;
    xavier   = admin;
    yves     = admin;

# unifield user = legacy user for Pakistan UF
    unifield = tunnelOnly;
    uf_sl_baama = tunnelOnly;
    uf_ke_embu = tunnelOnly;
    uf_sl_kenema = tunnelOnly;
    uf_cd_puc = tunnelOnly;
    uf_cd_masisi = tunnelOnly;
    uf_mz_maputo = tunnelOnly;
    uf_mz_beira = tunnelOnly;
    
    marco    = tunnelOnly;
    damien   = tunnelOnly;
    didier   = tunnelOnly;
    dirk     = tunnelOnly;
    godfried = tunnelOnly;
    joana    = tunnelOnly;
    kathy    = tunnelOnly;
    vini     = tunnelOnly;
    salima   = tunnelOnly;
    yusuph   = tunnelOnly // {
      hasShell = true;
      extraGroups = [ "docker" ];
    };

  };

  users.users = {
    # Only user with a password, but not usable via SSH.
    # To be used for console access in case of emergencies.
    msfocb = {
      isNormalUser = true;
      extraGroups  = [ "wheel" ];
      openssh.authorizedKeys.keyFiles = [];
    };

    # Lock the root user
    root = {
      hashedPassword = "!";
    };
  };

}

