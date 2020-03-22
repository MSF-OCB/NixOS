
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
  imports = [
    ./ocb_tunnels.nix
    ./ocb_users.nix
  ];

  settings.system.nix_channel = mkDefault "19.09";

  # nix-shell --packages python3 --command "python3 -c 'import crypt,getpass; print(crypt.crypt(getpass.getpass(), crypt.mksalt(crypt.METHOD_SHA512)))'"
  users.users.msfocb.hashedPassword = mkDefault
    "$6$FLtTyAhwtSyaTU1T$tnDBA5S5YeUF/UdO2KZtCVNieUlKGlL4iyGYtVKPI3Vfbyiu1BIH2j.BcScXPZbBbZ1P9PwKKh5B7lNoPr9o31";
}

