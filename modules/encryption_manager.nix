{ pkgs, ... }:

{
  config = let
    user = "encryption_manager";
  in {
    users.users."${user}" = {
      isNormalUser = false;
      isSystemUser = true;
    };

    systemd.services = let
      encryption_manager = pkgs.callPackage (pkgs.fetchFromGitHub {
        owner  = "msf-ocb";
        repo   = "nixos_encryption_manager";
        rev    = "81e4ab6b040d160505c06797a824bd7cdb233b7e";
        sha256 = "1vyxnrw4kylxkrpkiqy13knbpcia3v05nb4k832w3jf173al89xl";
      }) {};
    in {
      data_manager = {
        description   = "Web interface to manage the encrypted data partition";
        serviceConfig = {
          User    = user;
          Type    = "simple";
          Restart = "always";
        };
        script = ''
          ${data_manager}/bin/nixos_encryption_manager
        '';
      };
    };
  };
}

