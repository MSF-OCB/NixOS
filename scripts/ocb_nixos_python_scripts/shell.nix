{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = [ (pkgs.callPackage ./default.nix { doCheck = false; }) ];
}

