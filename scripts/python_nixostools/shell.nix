{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs =
    let scripts_pkg = pkgs.callPackage ./default.nix { doCheck = false; };
    in [ scripts_pkg ];
}

