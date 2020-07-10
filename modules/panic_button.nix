{ lib, config, pkgs, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg = config.settings.services.panic_button;
  crypto_cfg = config.settings.crypto;
in

{
  options = {
    settings.services.panic_button = {
      enable = mkEnableOption "the panic button service";

      listen_port = mkOption {
        type = types.ints.between 1 65535;
        default = 1234;
      };

      lock_retry_max_count = mkOption {
        type = types.int;
        default = 5;
      };

      verify_retry_max_count = mkOption {
        type = types.int;
        default = 50;
      };

      poll_interval = mkOption {
        type = types.int;
        default = 15;
      };

      disable_targets = mkOption {
        type = with types; listOf str;
        default = [ "<localhost>" ];
      };

      armed = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether the panic button service is armed.
          When disarming the service, no actual action will be taken when locking the server.
        '';
      };

    };
  };

  config = mkIf cfg.enable (let
    panic_button_user = "panic_button";

    panic_button = pkgs.callPackage (pkgs.fetchFromGitHub {
      owner = "r-vdp";
      repo = "panic_button";
      rev = "67e993a777cee75c4b381ddc95a84f79819b8e9a";
      sha256 = "1rf4hkmmpigp06awl8p4g8dmkysikaz1a5xz3injxlqz2gi4ax11";
    }) {};

    mkScript = name: content: let
      script = pkgs.writeShellScript name content;
    in if cfg.armed
       then script
       else "${pkgs.coreutils}/bin/true";

    mkWrapped = name: wrapped: mkScript name ''sudo --non-interactive ${wrapped}'';

    mkDisableKeyCommand = device: key_file: ''
      ${pkgs.cryptsetup}/bin/cryptsetup luksRemoveKey ${device} ${key_file}
    '';
    disableKeyCommands = mapAttrsToList (_: conf: mkDisableKeyCommand conf.device conf.key_file)
                                        crypto_cfg.mounts;
    rebootCommand = ''${pkgs.systemd}/bin/systemctl reboot'';
    lockCommands = concatStringsSep "\n" (disableKeyCommands ++ [ rebootCommand ]);

    lock_script_name = "panic_button_lock_script";
    lock_script_wrapped_name = "${lock_script_name}_wrapped";
    lock_script_wrapped = mkScript lock_script_wrapped_name lockCommands;
    lock_script = mkWrapped lock_script_name lock_script_wrapped;

    mkVerifyCommand = mount_point: ''
      if [ "$(${pkgs.utillinux}/bin/mountpoint --quiet ${mount_point}; echo $?)" = "0" ]; then
        echo "${mount_point} still mounted.."
        exit 1
      fi
    '';
    verifyMountPoints = concatStringsSep "\n" (mapAttrsToList (_: conf: mkVerifyCommand conf.mount_point)
                                                             crypto_cfg.mounts);
    verifyPreamble = ''set -e'';
    # TODO
    verifyUptimeCommand = ''
      echo "Something parsing the uptime command, exit 1 if the system has been up for a long time."
    '';

    verify_script_name = "panic_button_verify_script";
    verify_script = msf_lib.compose [ (mkScript verify_script_name)
                                      (concatStringsSep "\n") ]
                                    [ verifyPreamble
                                      verifyUptimeCommand
                                      verifyMountPoints ];

  in {
    networking.firewall.allowedTCPPorts = [ 1234 ];

    users.users."${panic_button_user}" = {
      isNormalUser = false;
      isSystemUser = true;
    };

    security.sudo.extraRules = [
      {
        users = [ panic_button_user ];
        commands = map (command: { inherit command; options = [ "SETENV" "NOPASSWD" ]; })
                       [ (toString lock_script) ];
      }
    ];

    systemd.services = {
      panic_button = {
        inherit (cfg) enable;
        description = "Web interface to lock the encrypted data partition";
        # Include the path to the security wrappers
        path = [ "/run/wrappers/" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User    = panic_button_user;
          Type    = "simple";
          Restart = "always";
        };
        script = let
          quoteString   = s: ''"${s}"'';
          formatTargets = concatMapStringsSep " " quoteString;
        in ''
          ${panic_button}/bin/nixos_panic_button --listen_port ${toString cfg.listen_port} \
                                                 --lock_script   ${lock_script} \
                                                 --verify_script ${verify_script} \
                                                 --lock_retry_max_count   ${toString cfg.lock_retry_max_count} \
                                                 --verify_retry_max_count ${toString cfg.verify_retry_max_count} \
                                                 --poll_interval ${toString cfg.poll_interval} \
                                                 --disable_targets ${formatTargets cfg.disable_targets}
        '';
      };
    };
  });
}

