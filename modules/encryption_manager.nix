{ pkgs, ... }:

{
  config = let
    encryption_manager_user = "encryption_manager";
  in {
    users.users."${encryption_manager_user}" = {
      isNormalUser = false;
      isSystemUser = true;
    };

    systemd.services = let
      encryption_manager = pkgs.callPackage (pkgs.fetchFromGitHub {
        owner  = "msf-ocb";
        repo   = "nixos_encryption_manager";
        rev    = "36bb50d97c11c1381a2a938390ce62fa0d2bef90";
        sha256 = "13cqz1akj5n2lq0b1asfnrscqjxr6kxlcp8kf4lcszfhk8zc1arm";
      }) {};
    in {
      encryption_manager = {
        description   = "Web interface to manage the encrypted data partition";
        serviceConfig = {
          User    = encryption_manager_user;
          Type    = "simple";
          Restart = "always";
        };
        script = ''
          ${encryption_manager}/bin/nixos_encryption_manager
        '';
      };
    };
  };
}

