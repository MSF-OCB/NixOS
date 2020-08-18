{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with nixpkgs.pkgs.python3Packages;

pkgs.mkShell {
  buildInputs = [ pkgs.python python3Packages.requests ];
}

