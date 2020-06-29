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

      lock_retry_max_count = mkOption {
        type = types.int;
        default = 5;
      };

      verify_retry_max_count = mkOption {
        type = types.int;
        default = 50;
      };

      disable_targets = mkOption {
        type = with types; listOf str;
        default = [ "<localhost>" ];
      };
    };
  };

  config = mkIf cfg.enable (let
    panic_button_user = "panic_button";
    panic_button = pkgs.callPackage (pkgs.fetchFromGitHub {
      owner = "r-vdp";
      repo = "panic_button";
      rev = "22c1cde16a8690391400f120cebd2f4c19d75a7f";
      sha256 = "04582mza6p561krxz9gvy9kwfqwfyk0x7y1lgvpiki6kh7xs02p2";
    }) {};

    mkWrapped = name: wrapped: pkgs.writeShellScript name ''sudo --non-interactive ${wrapped}'';
    mkScript = name: content: pkgs.writeShellScript name content;

    mkDisableKeyCommand = device: key_file: ''
      ${pkgs.cryptsetup}/bin/cryptsetup luksRemoveKey ${device} ${key_file}
    '';
    disableKeyCommands = mapAttrsToList (_: conf: mkDisableKeyCommand conf.device conf.key_file)
                                        crypto_cfg.mounts;
    rebootCommand = ''${pkgs.systemd}/bin/systemctl reboot'';
    lockCommands = concatStringsSep "\n" (disableKeyCommands ++ [ rebootCommand ]);

    lock_script_name = "panic_button_lock_script";
    lock_script_wrapper_name = "${lock_script_name}_wrapped";
    lock_script = mkScript lock_script_name lockCommands;
    lock_script_wrapped = mkWrapped lock_script_wrapper_name lock_script;

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

    verify_script_name = "verify_script";
    verify_script_wrapper_name = "verify_script_wrapped";
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
          ${panic_button}/bin/nixos_panic_button --lock_script   ${lock_script_wrapped} \
                                                 --verify_script ${verify_script} \
                                                 --lock_retry_max_count   ${toString cfg.lock_retry_max_count} \
                                                 --verify_retry_max_count ${toString cfg.verify_retry_max_count} \
                                                 --disable_targets ${formatTargets cfg.disable_targets}
        '';
      };
    };
  });
}

