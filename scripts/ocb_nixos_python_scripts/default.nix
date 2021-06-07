{ nixpkgs ? import <nixpkgs> {}
, pythonPkgs ? nixpkgs.pkgs.python3Packages
, doCheck ? true
}:

let
  pname   = "ocb_nixos_python_scripts";
  version = "0.1";
  src     = builtins.path { path = ./.; name = pname; };

  package = { buildPythonApplication, pyyaml, ansible, pynacl, mypy }:
    buildPythonApplication {
      inherit pname version src doCheck;

      checkInputs = [ mypy ];
      propagatedBuildInputs = [ pyyaml ansible pynacl ];

      checkPhase = ''
        mypy --warn-redundant-casts \
             --warn-unused-ignores \
             --warn-no-return \
             --warn-return-any \
             --warn-unreachable \
             --check-untyped-defs \
             $src/secret_lib \
             $src/ansible_vault_lib \
             *.py
      '';

      meta = {
        description = ''
          Collection of useful python scripts.
        '';
      };
    };
in
  pythonPkgs.callPackage package {}

