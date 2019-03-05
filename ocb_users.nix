
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, ... }:

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

    ramses   = admin;
    msg      = admin;
    thierry  = admin;
    mohammad = admin;
    marco    = admin;

    damien   = tunnelOnly;
    didier   = tunnelOnly;
    dirk     = tunnelOnly;
    godfried = tunnelOnly;
    joana    = tunnelOnly;
    kathy    = tunnelOnly;
    # IHS Informatics consultant for Bahmni
    # wasim    = tunnelOnly;
    yusuph   = tunnelOnly // {
      hasShell = true;
      extraGroups = [ "docker" ];
    };

  };

  # Only user with a password, but not usable via SSH.
  # To be used for console access in case of emergencies.
  users.extraUsers.msfocb = {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [];
  };

}

