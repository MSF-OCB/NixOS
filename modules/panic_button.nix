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
    };
  };

  config = mkIf cfg.enable (let
    panic_button_user = "panic_button";
    panic_button = pkgs.callPackage (pkgs.fetchFromGitHub {
      owner = "r-vdp";
      repo = "panic_button";
      rev = "0279ae48455622dcbebb30b1cd791ea05b6adf76";
      sha256 = "0si61ddf73rnwpk6wdgql6yy25qh0wy0bm7ggdjxp7vixqa6rcd0";
    }) {};

    mkWrapped = name: wrapped: pkgs.writeShellScript name ''sudo --non-interactive ${wrapped}'';
    mkScript = name: content: pkgs.writeShellScript name content;

    # TODO: remove quotes
    mkDisableKeyCommand = device: key_file: ''
      echo "${pkgs.cryptsetup}/bin/cryptsetup luksRemoveKey ${device} ${key_file}"
    '';
    disableKeyCommands = concatStringsSep "\n" (mapAttrsToList (_: conf: mkDisableKeyCommand conf.device conf.key_file)
                                                               crypto_cfg.mounts);

    lock_script_name = "panic_button_lock_script";
    lock_script_wrapper_name = "${lock_script_name}_wrapped";
    # TODO: add a reboot instruction (shutdown -r +1)
    lock_script = mkScript lock_script_name disableKeyCommands;
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
      echo Something parsing the uptime command, exit 1 if the system has been up for a long time
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
        enable = cfg.enable;
        description = "Web interface to lock the encrypted data partition";
        # Include the path to the security wrappers
        path = [ "/run/wrappers/" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User    = panic_button_user;
          Type    = "simple";
          Restart = "always";
        };
        script = ''
          ${panic_button}/bin/nixos_panic_button --lock_script   ${lock_script_wrapped} \
                                                 --verify_script ${verify_script} \
                                                 --lock_retry_max_count    5 \
                                                 --verify_retry_max_count 20 \
                                                 --disable_targets "<localhost>"
        '';
      };
    };
  });
}

