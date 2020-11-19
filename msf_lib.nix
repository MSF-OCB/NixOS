# Usage:
#   with (import ../msf_lib.nix);
#   msf_lib.<identifier>

with (import <nixpkgs> {});
with lib;

{
  msf_lib = let

    # compose [ f g h ] x == f (g (h x))
    compose = let
      apply = f: x: f x;
    in flip (foldr apply);

    applyN = n: f: compose (builtins.genList (_: f) n);

    applyTwice = applyN 2;

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
      };
      pub_key_pattern  = concatStringsSep "|" (attrValues key_patterns);
      description      =
        ''valid ${concatStringsSep " or " (attrNames key_patterns)} key, '' +
        ''meaning a string matching the pattern ${pub_key_pattern}'';
    in types.strMatching pub_key_pattern // { inherit description; };

    ifPathExists = path: optional (builtins.pathExists path) path;

    user_roles = let

      # Set of functions manipulating user roles that can be imported
      # This is a function which takes a config and returns the set of functions
      user_lib = config: let
        user_cfg = config.settings.users;

        # Function to define a user but override the name instead of taking the variable name
        withName = name: role: role // { inherit name; };

        # Function to create a user with a given role as an alias of an existing user
        alias = role: from:
          role //
          {
            inherit (user_cfg.users.${from}) enable;
            keyFileName = from;
          };

        # Function to create a tunnel user as an alias of an existing user
        aliasTunnel = alias remoteTunnel;
      in {
        inherit withName alias aliasTunnel;
      };

      # Admin users have shell access and belong to the wheel group
      # These are not enabled by default and should be enabled on a by-server basis
      admin = {
        enable      = mkDefault false;
        sshAllowed  = true;
        hasShell    = true;
        canTunnel   = true;
        extraGroups = [ "wheel" "docker" ];
      };

      # Global admin users have the same rights as admin users and are enabled by default
      globalAdmin = admin // { enable = true; };

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
      # These are not enabled by default and should be enabled on a by-server basis
      remoteTunnelMonitor = remoteTunnel // { forceCommand = ''
                                                ${pkgs.iproute}/bin/ss -tunl6 | \
                                                  ${pkgs.coreutils}/bin/sort -n | \
                                                  ${pkgs.gnugrep}/bin/egrep "\[::1\]:[0-9]{4}[^0-9]"
                                              '';
                                            };
    in {
      inherit user_lib admin globalAdmin localShell remoteTunnel remoteTunnelMonitor;
    };

    # Compatibility layer around
    # https://nixos.org/manual/nixos/stable/index.html#sec-settings-nix-representable
    # To be deleted when we upgraded all servers to 20.09.
    formats.compat = {
      yaml = _: {
        type = types.attrs;
        generate = name: value: pkgs.writeText name (builtins.toJSON value);
      };
    };

  in {
    inherit compose applyTwice filterEnabled ifPathExists
            host_name_type empty_str_type pub_key_type
            user_roles formats;
  };
}

