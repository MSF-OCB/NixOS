
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
with (import ../msf_lib.nix { inherit lib; });

{
  config = let
    host_name = config.settings.network.host_name;
  in {
    settings = {
      users.users = let
        users_json_path = ../org-spec/json/users.json;
        json_data = builtins.fromJSON (builtins.readFile users_json_path);

        # Load the list at path in the given attribute set and convert it to
        # an attribute set with every list element as a key and the value
        # set to a given constant.
        # Am attribute set like
        #   { per-host.benuc002.enable: [ "foo", "bar" ] }
        # will be transformed into an attribute set like
        #   { foo = const; bar = const; }
        listToAttrs_const = attrset: path: const: listToAttrs (map (name: nameValuePair name const)
                                                              (attrByPath path [] attrset));
      in
        # recursiveUpdate merges the two resulting attribute sets recursively
        recursiveUpdate (listToAttrs_const json_data [ "users" "tunnel_only" ]                      msf_lib.user_roles.tunnelOnly)
                        (listToAttrs_const json_data [ "users" "per-host" "${host_name}" "enable" ] { enable = true; });

      reverse_tunnel.tunnels = let
        tunnel_json_path = ../org-spec/json/tunnels.json;
        json_data = builtins.fromJSON (builtins.readFile tunnel_json_path);
      in
        json_data.tunnels.per-host;
    };
  };
}

