{ config, lib, pkgs, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg            = config.settings.users;
  sys_cfg        = config.settings.system;
  reverse_tunnel = config.settings.reverse_tunnel;

  userOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };

      enable = mkEnableOption "the user";

      sshAllowed = mkOption {
        type    = types.bool;
        default = false;
      };

      extraGroups = mkOption {
        type    = with types; listOf str;
        default = [];
      };

      hasShell = mkOption {
        type    = types.bool;
        default = false;
      };

      canTunnel = mkOption {
        type    = types.bool;
        default = false;
      };

      keyFileName = mkOption {
        type = types.str;
      };

      forceCommand = mkOption {
        type    = with types; nullOr str;
        default = null;
      };
    };
    config = {
      name = mkDefault name;
      # We need to actually resolve the name from the config,
      # the default value above might have been overridden.
      keyFileName = mkDefault cfg.users.${name}.name;
    };
  };

  whitelistOpts = { name, config, ... }: {
    options = {
      enable = mkEnableOption "the whitelist";

      group = mkOption {
        type = types.str;
      };

      commands = mkOption {
        type    = with types; listOf str;
        default = [ ];
      };
    };
    config = {
      group = mkDefault name;
    };
  };

in {

  options = {
    settings.users = {
      users = mkOption {
        type    = with types; attrsOf (submodule userOpts);
        default = {};
      };

      whitelistGroups = mkOption {
        type    = with types; attrsOf (submodule whitelistOpts);
        default = {};
      };

      shell-user-group = mkOption {
        type     = types.str;
        default  = "shell-users";
        readOnly = true;
      };

      ssh-group = mkOption {
        type     = types.str;
        default  = "ssh-users";
        readOnly = true;
        description = ''
          Group to tag users who are allowed log in via SSH
          (either for shell or for tunnel access).
        '';
      };

      fwd-tunnel-group = mkOption {
        type     = types.str;
        default  = "ssh-fwd-tun-users";
        readOnly = true;
      };

      rev-tunnel-group = mkOption {
        type     = types.str;
        default  = "ssh-rev-tun-users";
        readOnly = true;
      };

      robot = {
        enable = mkEnableOption "the robot user";

        username = mkOption {
          type     = types.str;
          default  = "robot";
          readOnly = true;
          description = ''
            User used for automated access (eg. Ansible)
          '';
        };
      };
    };
  };

  config = let
    toKeyPath = user: sys_cfg.pub_keys_path + ("/" + user.keyFileName);
  in {
    settings.users.users.${cfg.robot.username} =
      mkIf cfg.robot.enable msf_lib.user_roles.globalAdmin;

    users = {
      mutableUsers = false;

      # !! These lines are very important !!
      # Without it, the ssh groups are not created
      # and no-one has SSH access to the system!
      groups = {
        ${cfg.ssh-group}        = { };
        ${cfg.fwd-tunnel-group} = { };
        ${cfg.rev-tunnel-group} = { };
        ${cfg.shell-user-group} = { };
      }
      //
      # Create the groups that are used for whitelisting sudo commands
      msf_lib.compose [ (mapAttrs (_: _: {}))
                        msf_lib.filterEnabled ]
                      cfg.whitelistGroups;

      users = let
        hasForceCommand = user: ! isNull user.forceCommand;
        hasShell = user: user.hasShell || (hasForceCommand user && reverse_tunnel.relay.enable);
        mkUser = _: user: {
          name         = user.name;
          isNormalUser = user.hasShell;
          isSystemUser = ! user.hasShell;
          extraGroups  = user.extraGroups ++
                         (optional (user.sshAllowed || user.canTunnel) cfg.ssh-group) ++
                         (optional user.canTunnel cfg.fwd-tunnel-group) ++
                         (optional user.hasShell  cfg.shell-user-group);
          shell        = if (hasShell user) then config.users.defaultUserShell else pkgs.nologin;
          openssh.authorizedKeys.keyFiles = [ (toKeyPath user) ];
        };
        mkUsers = msf_lib.compose [ (mapAttrs mkUser)
                                    msf_lib.filterEnabled ];
      in mkUsers cfg.users;
    };

    settings.reverse_tunnel.relay.tunneller.keyFiles = let
      mkKeyFiles  = msf_lib.compose [ unique
                                      (mapAttrsToList (_: user: toKeyPath user))
                                      (filterAttrs (_: user: user.canTunnel)) ];
    in mkKeyFiles cfg.users;

    security.sudo.extraRules = let
      addDenyAll = cmds: [ "!ALL" ] ++ cmds;
      mkRule = name: opts: { groups = [ opts.group ];
                             runAs = "root";
                             commands = map (command: { inherit command;
                                                        options = [ "SETENV" "NOPASSWD" ]; })
                                            (addDenyAll opts.commands); };
    in msf_lib.compose [ (mapAttrsToList mkRule)
                         msf_lib.filterEnabled ]
                       cfg.whitelistGroups;
  };
}

