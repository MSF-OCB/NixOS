
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, pkgs, ... }:

with lib;
with (import ../msf_lib.nix);

let
  cfg            = config.settings.users;
  org_cfg        = config.settings.org;
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

      isSystemUser = mkOption {
        type    = types.bool;
        default = false;
      };

      canTunnel = mkOption {
        type    = types.bool;
        default = false;
      };

      forceMonitorCommand = mkOption {
        type    = types.bool;
        default = false;
        description = ''
          Set the port monitor command as the SSH forced command on the relays.
        '';
      };
    };
    config = {
      name = mkDefault name;
    };
  };

in {

  options = {
    settings.users = {
      users = mkOption {
        type    = with types; attrsOf (submodule userOpts);
        default = [];
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
    };
  };

  config = let
    toKeyPath = name: org_cfg.keys_path + ("/" + name);
  in {
    users = {
      mutableUsers = false;

      # !! This line is very important !!
      # Without it, the ssh-users group is not created
      # and no-one has SSH access to the system!
      groups."${cfg.ssh-group}"        = { };
      groups."${cfg.fwd-tunnel-group}" = { };
      groups."${cfg.rev-tunnel-group}" = { };
      groups."${cfg.shell-user-group}" = { };

      users = let
        hasShell = user: user.hasShell || (user.forceMonitorCommand && reverse_tunnel.relay.enable);
        mkUser = name: user: {
          name         = name;
          isNormalUser = user.hasShell;
          isSystemUser = user.isSystemUser;
          extraGroups  = user.extraGroups ++
                         (optional (user.sshAllowed || user.canTunnel) cfg.ssh-group) ++
                         (optional user.canTunnel cfg.fwd-tunnel-group) ++
                         (optional user.hasShell  cfg.shell-user-group);
          shell        = if (hasShell user) then config.users.defaultUserShell else pkgs.nologin;
          openssh.authorizedKeys.keyFiles = [ (toKeyPath name) ];
        };
        mkUsers = msf_lib.compose [ (mapAttrs mkUser)
                                    msf_lib.filterEnabled ];
      in mkUsers cfg.users;
    };

    settings.reverse_tunnel.relay.tunneller.keyFiles = let
      mkKeyFiles = msf_lib.compose [ (mapAttrsToList (name: _: toKeyPath name))
                                     (filterAttrs (_: user: user.canTunnel)) ];
    in mkKeyFiles cfg.users;
  };
}

