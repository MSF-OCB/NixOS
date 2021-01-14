{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs.pkgs;

mkShell {
  buildInputs = [
    ansible
    python3
    python3Packages.pynacl
    python3Packages.pyyaml
  ];
}

