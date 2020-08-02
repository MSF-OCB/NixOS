{ config, lib, ... }:

with lib;
with (import ../msf_lib.nix).msf_lib.user_roles;

let
  user_cfg = config.settings.users;
in

{
  settings.users = {
    robot.enable = true;

    users = let
      aliasTunnel = from: remoteTunnel // { inherit (user_cfg.users."${from}") enable; keyFileName = from; };
    in {
      # Super admins, enabled by default on all servers
      ramses  = admin;
      thierry = admin;
      yves    = admin;

      # Users with admin access, need to be enabled explicitly
      ian      = admin_base;
      mohammad = admin_base;

      # Field support team
      ali    = fieldSupport;
      deepak = fieldSupport;
      paul   = fieldSupport;

      # Admin access for field support team
      ali_admin    = admin_base // { name = "ali"; };
      deepak_admin = admin_base // { name = "deepak"; };
      paul_admin   = admin_base // { name = "paul"; };

      yusuph   = remoteTunnel // {
        hasShell    = true;
        extraGroups = [ "docker" ];
      };

      damien   = remoteTunnel // {
        hasShell    = true;
        extraGroups = [ "docker" ];
      };

      # Msfocb-kinshasa-sida-Ehmanager
      gauthier = localShell // {
        extraGroups = [ "docker" ];
      };

      # Aliases for old tunnel keys which do not
      # download the tunnel script from github
      uf_bd_coxcoord      = aliasTunnel "tnl_bd_coxcoord";
      uf_bi_bujumbura     = aliasTunnel "tnl_bi_bujumbura";
      uf_cd_goma          = aliasTunnel "tnl_cd_goma";
      uf_cd_kinshasacoord = aliasTunnel "tnl_cd_kinshasacoord";
      uf_cd_masisi        = aliasTunnel "tnl_cd_masisi";
      uf_cd_puc           = aliasTunnel "tnl_cd_puc";
      uf_ke_embu          = aliasTunnel "tnl_ke_embu";
      uf_mz_beira         = aliasTunnel "tnl_mz_beira";
      uf_pk_karachi       = aliasTunnel "tnl_pk_karachi";
      uf_sl_baama         = aliasTunnel "tnl_sl_baama";
      uf_sl_freetown      = aliasTunnel "tnl_sl_freetown";
      uf_sl_kenema        = aliasTunnel "tnl_sl_kenema";
      unifield            = aliasTunnel "tnl_legacy";
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

