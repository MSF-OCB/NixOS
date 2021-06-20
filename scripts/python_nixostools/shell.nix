{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages =
    let scripts_pkg = pkgs.callPackage ./default.nix { doCheck = false; };
    in [ scripts_pkg ];
}

