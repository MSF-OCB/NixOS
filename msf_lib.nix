# Usage:
#   with (import ../msf_lib.nix);
#   msf_lib.<identifier>

with (import <nixpkgs> {}).lib;

{
  msf_lib = {

    # compose [ f g h ] x == f (g (h x))
    compose = let
      apply = f: x: f x;
    in flip (foldr apply);

    filterEnabled = filterAttrs (_: conf: conf.enable);

    # A type for host names, host names consist of:
    #   * a first character which is an upper or lower case ascii character
    #   * followed by zero or more of: dash (-), upper case ascii, lower case ascii, digit
    #   * followed by an upper or lower case ascii character or a digit
    host_name_type =
      types.strMatching "^[[:upper:][:lower:]][-[:upper:][:lower:][:digit:]]*[[:upper:][:lower:][:digit:]]$";
    empty_str_type = types.strMatching "^$" // {
      description = "empty string";
    };
    pub_key_type   = let
      key_data_pattern = "[[:lower:][:upper:][:digit:]\\/+]";
      key_patterns     = {
        ssh-ed25519         = "^ssh-ed25519 ${key_data_pattern}{68}$";
        ecdsa-sha2-nistp256 = "^ecdsa-sha2-nistp256 ${key_data_pattern}{139}=$";
        ecdsa-sha2-nistp521 = "^ecdsa-sha2-nistp521 ${key_data_pattern}{230}==$";
      };
      pub_key_pattern  = concatStringsSep "|" (attrValues key_patterns);
      description      = ''valid ${concatStringsSep " or " (attrNames key_patterns)} key, meaning a string matching the pattern ${pub_key_pattern}'';
    in types.strMatching pub_key_pattern // { inherit description; };

    importIfExists = path: optional (builtins.pathExists path) path;

    user_roles = rec {
      # admin_base users have shell access, belong to the wheel group, but are not enabled by default
      admin_base = {
        enable      = mkDefault false;
        sshAllowed  = true;
        hasShell    = true;
        canTunnel   = true;
        extraGroups = [ "wheel" "docker" ];
      };
      # Admin users have the same rights as admin_base users and are enabled by default
      admin = admin_base // { enable = true; };

      localShell = {
        enable     = mkDefault false;
        sshAllowed = true;
        hasShell   = true;
        canTunnel  = false;
      };

      # Users who can tunnel only
      # These are not enabled by default and should be enabled on a by-server basis
      remoteTunnel = {
        enable     = mkDefault false;
        sshAllowed = true;
        hasShell   = false;
        canTunnel  = true;
      };
      # Users who are tunnel-only but can tunnel to all NixOS servers and query the open tunnels
      fieldSupport = remoteTunnel // { forceMonitorCommand = true; };
    };
  };
}

