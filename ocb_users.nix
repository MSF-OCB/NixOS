
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

    ssh-group = config.settings.users.ssh-group;
    admin = {
      enable    = true;
      hasShell  = true;
      canTunnel = true;
      extraGroups = [ "wheel" "docker" ssh-group ];
    };
    tunnelOnly = {
      hasShell  = false;
      canTunnel = true;
      extraGroups = [ ssh-group ];
    };

  in {

    ramses   = admin;
    msg      = admin;
    thierry  = admin;
    mohammad = admin;

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
      extraGroups = [ "docker" ssh-group ];
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

