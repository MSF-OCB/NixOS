
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{ config, lib, ...}:

with lib;
with (import ../msf_lib.nix);

{
  config = let
    host_name = config.settings.network.host_name;
    loadJSON  = path: builtins.fromJSON (builtins.readFile path);
  in {
    settings = {
      users.users = let
        users_json_path = ../org-spec/json/users.json;
        json_data       = loadJSON users_json_path;
        remoteTunnel    = msf_lib.user_roles.remoteTunnel;

        # Load the list at path in the given attribute set and convert it to
        # an attribute set with every list element as a key and the value
        # set to a given constant.
        # The function onAbsent is called when the specified path does not exist.
        # Example:
        #   listToAttrs_const [ "per-host" "benuc002" "enable" ] val [] { per-host.benuc002.enable = [ "foo", "bar" ]; }
        # will yield:
        #   { foo = val; bar = val; }
        # If the given path cannot be found, the value of onAbsent will be returned.
        listToAttrs_const = path: const: onAbsent: attrset: listToAttrs (map (name: nameValuePair name const)
                                                                        (attrByPath path onAbsent attrset));
        # recursiveUpdate merges the two resulting attribute sets recursively
        recursiveMerge = foldr recursiveUpdate {};
        # Given the host name and the json data, retrieve the enabled roles for the given host
        enabledRoles   = host_name: attrByPath [ "users" "per-host" host_name "enable_roles" ] [];
        onRoleAbsent   = role: host_name: abort ''The role "${role}" which was enabled for host "${host_name}" is not defined.'';
      in
        recursiveMerge ([ (listToAttrs_const [ "users" "remote_tunnel" ]               remoteTunnel       [] json_data)
                          (listToAttrs_const [ "users" "per-host" host_name "enable" ] { enable = true; } [] json_data) ] ++
                          (map (role: listToAttrs_const [ "users" "roles" role ] { enable = true; } (onRoleAbsent role host_name) json_data)
                               (enabledRoles host_name json_data)));

      reverse_tunnel.tunnels = let
        tunnel_json_path = ../org-spec/json/tunnels.json;
        json_data        = loadJSON tunnel_json_path;
      in
        json_data.tunnels.per-host;
    };
  };
}

