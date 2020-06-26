{ lib, ... }:

with lib;
with (import ../msf_lib.nix).msf_lib.user_roles;

{
  settings.users.users = {

    # User used for automated access (eg. Ansible)
    robot    = admin;

    mohammad = admin;
    ramses   = admin;
    thierry  = admin;
    xavier   = admin;
    yves     = admin;

    ian      = admin_base;

    # Field support team
    ali      = fieldSupport;
    deepak   = fieldSupport;
    paul     = fieldSupport;

    yusuph   = remoteTunnel // {
      hasShell    = true;
      extraGroups = [ "docker" ];
    };
    
    # Msfocb-kinshasa-sida-Ehmanager@brussels.msf.org
    gauthier = localShell // {
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
      # nix-shell --packages python3 \
      #           --command "python3 -c 'import crypt,getpass; \
      #                                  print(crypt.crypt(getpass.getpass(), \
      #                                                    crypt.mksalt(crypt.METHOD_SHA512)))'"
      hashedPassword = mkDefault
        "$6$FLtTyAhwtSyaTU1T$tnDBA5S5YeUF/UdO2KZtCVNieUlKGlL4iyGYtVKPI3Vfbyiu1BIH2j.BcScXPZbBbZ1P9PwKKh5B7lNoPr9o31";
    };

    # Lock the root user
    root = {
      hashedPassword = mkForce "!";
    };
  };
}

