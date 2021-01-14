{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs.pkgs;

mkShell {
  buildInputs = [
    python3
    python3Packages.pynacl
    python3Packages.pyyaml
  ];
}

