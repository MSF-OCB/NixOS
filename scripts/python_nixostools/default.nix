{ nixpkgs ? import <nixpkgs> {}
, pythonPkgs ? nixpkgs.pkgs.python3Packages
, doCheck ? true
}:

let
  pname   = "ocb_python_nixostools";
  version = "0.1";
  src     = builtins.path { path = ./.; name = pname; };

  package = { buildPythonApplication, ansible, mypy, pynacl, pyyaml, requests }:
    buildPythonApplication {
      inherit pname version src doCheck;

      checkInputs = [ mypy ];
      propagatedBuildInputs = [ ansible pynacl pyyaml requests ];

      checkPhase = ''
        mypy --warn-redundant-casts \
             --warn-unused-ignores \
             --warn-no-return \
             --warn-return-any \
             --warn-unreachable \
             --check-untyped-defs \
             ${src}/nixostools
      '';

      meta = {
        description = ''
          Collection of useful python scripts.
        '';
      };
    };
in
  pythonPkgs.callPackage package {}

