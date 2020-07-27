{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.settings.services.panic_button;
  crypto_cfg = config.settings.crypto;
in

{
  options = {
    settings.services.panic_button = {
      enable = mkEnableOption "the panic button service";

      listen_port = mkOption {
        type = types.port;
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

    # Use the prefetch_git script in the NixOS repo to update the values below
    panic_button = let
      rev    = "884c46b0e826e715bcc8cab169565b565ac80ae4";
      sha256 = "0khykc1507mdgb832b64dki9pvx6m7dkrqkwd484a05d5xf6jx7v";
    in pkgs.callPackage (pkgs.fetchFromGitHub {
      owner = "msf-ocb";
      repo  = "panic_button";
      inherit rev sha256;
    }) { version = rev; };

    mkScript = name: content: let
      script = pkgs.writeShellScript name content;
    in if cfg.armed
       then script
       else "${pkgs.coreutils}/bin/true";

    mkWrapper = name: wrapped: mkScript name ''sudo --non-interactive ${wrapped}'';

    lock_script = let

      script_name  = "panic_button_lock_script";
      wrapped_name = "${script_name}_wrapped";

      disableKeyCommands = let
        mkDisable = device: key_file: ''
          ${pkgs.cryptsetup}/bin/cryptsetup luksRemoveKey ${device} ${key_file}
        '';
      in mapAttrsToList (_: conf: mkDisable conf.device conf.key_file)
                        crypto_cfg.mounts;

      rebootCommand = ''${pkgs.systemd}/bin/systemctl reboot'';

      wrapped = let
        commands = concatStringsSep "\n" (disableKeyCommands ++ [ rebootCommand ]);
      in mkScript wrapped_name commands;

    in mkWrapper script_name wrapped;

    verify_script = let

      script_name = "panic_button_verify_script";

      verifyUptime = ''
        uptime=$(${pkgs.coreutils}/bin/cut -d '.' -f 1 /proc/uptime)
        if [ "''${uptime}" -gt 240 ]; then
          echo "Seems like the system did not reboot.."
          exit 1
        fi
      '';

      verifyMountPoints = let
        mkVerify = mount_point: ''
          if [ "$(${pkgs.utillinux}/bin/mountpoint --quiet ${mount_point}; echo $?)" = "0" ]; then
            echo "${mount_point} still mounted.."
            exit 1
          fi
        '';
      in mapAttrsToList (_: conf: mkVerify conf.mount_point) crypto_cfg.mounts;

      commands = concatStringsSep "\n" ( [ verifyUptime ] ++ verifyMountPoints);

    in mkScript script_name commands;

  in {
    networking.firewall.allowedTCPPorts = [ cfg.listen_port ];

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
        # Include the path to the security wrappers to make sudo available
        path = [ "/run/wrappers/" ];
        environment = { PYTHONUNBUFFERED = "1"; };
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

