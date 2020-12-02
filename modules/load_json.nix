{ config, lib, ...}:

with lib;
with (import ../msf_lib.nix);

{
  config = let
    sys_cfg  = config.settings.system;
    hostName = config.settings.network.host_name;
  in {
    settings = {
      users.users = let
        users_json_path = sys_cfg.users_json_path;
        json_data       = importJSON users_json_path;
        remoteTunnel    = msf_lib.user_roles.remoteTunnel;

        # Load the list at path in an attribute set and convert it to
        # an attribute set with every list element as a key and the value
        # set to a given constant value.
        # If the given path cannot be found in the loaded JSON structure,
        # then the value of onAbsent will be used as input instead.
        #
        # Example:
        #   listToAttrs_const [ "per-host" "benuc002" "enable" ]
        #                     val
        #                     []
        #                     { per-host.benuc002.enable = [ "foo", "bar" ]; }
        # will yield:
        #   { foo = val; bar = val; }
        listToAttrs_const = path: value: onAbsent:
          msf_lib.compose [ (flip genAttrs (const value))
                            (attrByPath path onAbsent) ];

        # recursiveUpdate merges the two resulting attribute sets recursively
        recursiveMerge = foldr recursiveUpdate {};

        remoteTunnelUsers = listToAttrs_const [ "users" "remote_tunnel" ]
                                              remoteTunnel
                                              [] json_data;
        enabledUsers      = listToAttrs_const [ "users" "per-host" hostName "enable" ]
                                              { enable = true; }
                                              [] json_data;

        enabledUsersByRoles = let
          # Given the host name and the json data,
          # retrieve the enabled roles for the given host
          enabledRoles = hostName:
            attrByPath [ "users" "per-host" hostName "enable_roles" ] [];
          onRoleAbsent = role: hostName:
            abort ''The role "${role}" which was enabled for host "${hostName}" is not defined.'';
          # Activate the users in the given role
          activateRole = hostName: role:
            listToAttrs_const [ "users" "roles" role ]
                              { enable = true; }
                              (onRoleAbsent role hostName)
                              json_data;
          activateRoles = hostName: map (activateRole hostName);
        in activateRoles hostName (enabledRoles hostName json_data);
      in recursiveMerge ([ remoteTunnelUsers
                           enabledUsers ] ++
                         enabledUsersByRoles);

      reverse_tunnel.tunnels = let
        tunnel_json_path = sys_cfg.tunnels_json_path;
        json_data        = importJSON tunnel_json_path;
      in json_data.tunnels.per-host;
    };
  };
}

