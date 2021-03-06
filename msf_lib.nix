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

    applyN = n: f: compose (genList (const f) n);

    applyTwice = applyN 2;

    filterEnabled = filterAttrs (_: conf: conf.enable);

    /* Find duplicate elements in a list in O(n) time

       Example:
         find_duplicates [ 1 2 2 3 4 4 4 5 ]
         => [ 2 4 ]
    */
    find_duplicates = let
      /* Function to use with foldr
         Given an element and a set mapping elements (as Strings) to booleans,
         it will add the element to the set with a value of:
           - false if the element was not previously there, and
           - true  if the element had been added already
         The result after folding, is a set mapping duplicate elements to true.
      */
      update_duplicates_set = el: set: let
        is_duplicate = el: hasAttr (toString el);
      in set // { ${toString el} = is_duplicate el set; };
    in compose [
      attrNames                        # return the name only
      (filterAttrs (flip const))       # filter on trueness of the value
      (foldr update_duplicates_set {}) # fold to create the duplicates set
    ];

    # recursiveUpdate merges the two resulting attribute sets recursively
    recursiveMerge = foldr recursiveUpdate {};

    /* A type for host names, host names consist of:
        * a first character which is an upper or lower case ascii character
        * followed by zero or more of: dash (-), upper case ascii, lower case ascii, digit
        * followed by an upper or lower case ascii character or a digit
    */
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

    traceImportJSON = compose [
      importJSON
      (traceValFn (f: "Loading file ${toString f}..."))
    ];

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

      remoteTunnelWithShell = {
        enable      = mkDefault false;
        sshAllowed  = true;
        hasShell    = true;
        canTunnel   = true;
      };

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

      # Users who are tunnel-only but can tunnel to all NixOS servers and query
      # the open tunnels.
      # These are not enabled by default and should be enabled on a by-server basis.
      remoteTunnelMonitor = remoteTunnel // { forceCommand = ''
                                                ${pkgs.iproute}/bin/ss -tunl6 | \
                                                  ${pkgs.coreutils}/bin/sort -n | \
                                                  ${pkgs.gnugrep}/bin/egrep "\[::1\]:[0-9]{4}[^0-9]"
                                              '';
                                            };
    in {
      inherit user_lib admin globalAdmin remoteTunnelWithShell
              localShell remoteTunnel remoteTunnelMonitor;
    };

    # Compatibility layer around
    # https://nixos.org/manual/nixos/stable/index.html#sec-settings-nix-representable
    # To be deleted when we upgraded all servers to 20.09.
    formats.compat = {
      yaml = const {
        type = types.attrs;
        generate = name: value: pkgs.writeText name (builtins.toJSON value);
      };
    };

    # Prepend a string with a given number of spaces
    # indentStr :: Int -> String -> String
    indentStr = n: str: let
      spacesN = compose [ concatStrings (genList (const " ")) ];
    in (spacesN n) + str;

    reset_git = { branch
                , git_options
                , indent ? 0 }: let
      git = "${pkgs.git}/bin/git";
      mkOptionsStr = concatStringsSep " ";
      mkGitCommand = git_options: cmd: "${git} ${mkOptionsStr git_options} ${cmd}";
      mkGitCommandIndented = indent: git_options:
        compose [ (indentStr indent) (mkGitCommand git_options) ];
    in concatMapStringsSep "\n" (mkGitCommandIndented indent git_options) [
      # The following line is only used to avoid the warning emitted by git.
      # We will reset the local repo anyway and remove all local changes.
      "config pull.rebase true"
      "fetch origin ${branch}"
      "checkout ${branch} --"
      "reset --hard origin/${branch}"
      "clean -d --force"
      "pull"
    ];

    clone_and_reset_git = { clone_dir
                          , github_repo
                          , branch
                          , git_options ? []
                          , indent ? 0 }: ''
        if [ ! -d "${clone_dir}" ] || [ ! -d "${clone_dir}/.git" ]; then
          if [ -d "${clone_dir}" ]; then
            # The directory exists but is not a git clone
            ${pkgs.coreutils}/bin/rm --recursive --force "${clone_dir}"
          fi
          ${pkgs.coreutils}/bin/mkdir --parent "${clone_dir}"
          ${pkgs.git}/bin/git \
            clone "git@github.com:MSF-OCB/${github_repo}.git" \
            "${clone_dir}"
        fi
        ${reset_git { inherit branch indent;
                      git_options = git_options ++ [ "-C" ''"${clone_dir}"'' ]; }}
    '';

    mkDeploymentService = { config
                          , deploy_dir_name
                          , github_repo
                          , git_branch ? "main"
                          , pre-compose_script ? "deploy/pre-compose.sh"
                          , extra_script ? ""
                          , restart ? false
                          , force_build ? false
                          , docker_compose_files ? [ "docker-compose.yml" ] }: let
      secrets_dir = config.settings.system.secrets.dest_directory;
      deploy_dir = "/opt/${deploy_dir_name}";
      pre-compose_script_path = "${deploy_dir}/${pre-compose_script}";
    in {
      serviceConfig.Type = "oneshot";

      # We need to explicitly set the docker runtime dependency
      # since docker-compose does not depend on docker.
      #
      # nix is included so that nix-shell can be used in the external scripts
      # called dynamically by this function
      path = with pkgs; [ nix docker ];

      environment = let
        inherit (config.settings.system) private_key;
      in {
        # We need to set the NIX_PATH env var so that we can resolve <nixpkgs>
        # references when using nix-shell.
        inherit (config.environment.sessionVariables) NIX_PATH;
        GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh " +
                          "-i ${private_key} " +
                          "-o IdentitiesOnly=yes " +
                          "-o StrictHostKeyChecking=yes";
        MSFOCB_SECRETS_DIRECTORY = secrets_dir;
        MSFOCB_DEPLOY_DIR = deploy_dir;
      };
      script = let
        docker_credentials_file = "${secrets_dir}/docker_private_repo_creds";
      in ''
        ${clone_and_reset_git { inherit github_repo;
                                clone_dir = deploy_dir;
                                branch = git_branch; }}

        # Login to our private docker repo (hosted on github)
        if [ -f ${docker_credentials_file} ]; then
          # Load private repo variables
          source ${docker_credentials_file}

          echo ''${DOCKER_PRIVATE_REPO_PASS} | \
          ${pkgs.docker}/bin/docker login \
            --username "''${DOCKER_PRIVATE_REPO_USER}" \
            --password-stdin \
            "''${DOCKER_PRIVATE_REPO_URL}"

          docker_login_successful=true
        else
          echo "No docker credentials file found, skipping docker login."
        fi

        if [ -x "${pre-compose_script_path}" ]; then
          "${pre-compose_script_path}"
        else
          echo "Pre-compose script (${pre-compose_script_path}) does not exist or is not executable, skipping."
        fi

        ${extra_script}

        ${pkgs.docker-compose}/bin/docker-compose \
          --project-directory "${deploy_dir}" \
          ${concatMapStringsSep " " (s: ''--file "${deploy_dir}/${s}"'') docker_compose_files} \
          --ansi never \
          ${if restart
            then "restart"
            else ''up --detach --remove-orphans ${optionalString force_build "--build"}''
          }

        if [ "''${docker_login_successful}" = true ]; then
          ${pkgs.docker}/bin/docker logout "''${DOCKER_PRIVATE_REPO_URL}"
        fi
      '';
    };
  in {
    inherit compose applyTwice filterEnabled find_duplicates recursiveMerge
            ifPathExists traceImportJSON
            host_name_type empty_str_type pub_key_type
            user_roles formats
            indentStr reset_git clone_and_reset_git mkDeploymentService;
  };
}

