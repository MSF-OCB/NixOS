{ config, lib, ...}:

with lib;
with (import ../msf_lib.nix);

{
  config = let
    sys_cfg  = config.settings.system;
    hostName = config.settings.network.host_name;

    get_json_paths = dir: msf_lib.compose [
      (mapAttrsToList (name: _: dir + ("/" + name)))
      (filterAttrs (name: type: type == "regular" && hasSuffix ".json" name))
      builtins.readDir
    ] dir;

    tunnel_json_paths = get_json_paths sys_cfg.tunnels_json_dir_path;

    # Note: the warning only gets printed once per file.
    # Since the value of the default expression does not depend on the input
    # argument to the function, Nix memoizes the result of the trace call and
    # the side-effect only occurs once.
    get_tunnels_set = let
      tunnels_json_path = [ "tunnels" "per-host" ];
      warn_string = "ERROR: JSON structure does not contain the attribute " +
                    concatStringsSep "." tunnels_json_path;
    in attrByPath tunnels_json_path (abort warn_string);
  in {

    assertions = let
      json_to_names = msf_lib.compose [
        attrNames
        get_tunnels_set
        msf_lib.traceImportJSON
      ];
      mkDuplicates = msf_lib.compose [
        msf_lib.find_duplicates
        (concatMap json_to_names) # map the JSON files to the server names
      ];
      duplicates = mkDuplicates tunnel_json_paths;
    in [
      {
        assertion = length duplicates == 0;
        message   = "Duplicate entries found in the tunnel definitions. " +
                    "Duplicates: " +
                    concatStringsSep ", " duplicates;
      }
    ];

    settings = {
      users.users = let
        users_json_path = sys_cfg.users_json_path;
        json_data       = msf_lib.traceImportJSON users_json_path;
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
      in msf_lib.recursiveMerge ([ remoteTunnelUsers
                                   enabledUsers ] ++
                                   enabledUsersByRoles);

      reverse_tunnel.tunnels = let
        # We add the SSH tunnel by default
        addSshTunnel  = tunnel: let
          ssh_tunnel = {
            reverse_tunnels = {
              ssh = {
                prefix = 0;
                forwarded_port = 22;
              };
            };
          };
        in recursiveUpdate tunnel ssh_tunnel;
        addSshTunnels = mapAttrs (_: addSshTunnel);
        load_tunnel_files = msf_lib.compose [
          addSshTunnels
          # We check in an assertion above that the two attrsets have an
          # empty intersection, so we do not need to worry about the order
          # in which we merge them here.
          msf_lib.recursiveMerge
          (map (msf_lib.compose [
                  get_tunnels_set
                  msf_lib.traceImportJSON
                ]))
        ];
      in load_tunnel_files tunnel_json_paths;
    };
  };
}

