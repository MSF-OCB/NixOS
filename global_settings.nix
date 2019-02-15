{
  
  default_users = [
    ./users/msfocb.nix
    ./users/ramses.nix
    ./users/manu.nix
    ./users/mohammad.nix
    ./users/thierry.nix
  ];

  tunneller_keyfiles = [
    ./keys/didier
    ./keys/dirk
    ./keys/joana
    ./keys/kathy
    ./keys/manu
    ./keys/mohammad
    ./keys/ramses
    ./keys/thierry
    ./keys/yusuph
  ];

  reverse_tunnel_config = [
    { name = "google";     host = "msfrelay1.msfict.info";     port_prefix = 0; }
    { name = "ixelles";    host = "ehealthsshrelayhq1.msf.be"; port_prefix = 0; }
    { name = "ixelles-ip"; host = "194.78.17.132";             port_prefix = 1; }
  ];

  # python3 -c 'import crypt,getpass; print(crypt.crypt(getpass.getpass(), crypt.mksalt(crypt.METHOD_SHA512)))'
  admin_user_hashedPassword = "$6$FLtTyAhwtSyaTU1T$tnDBA5S5YeUF/UdO2KZtCVNieUlKGlL4iyGYtVKPI3Vfbyiu1BIH2j.BcScXPZbBbZ1P9PwKKh5B7lNoPr9o31";

}

