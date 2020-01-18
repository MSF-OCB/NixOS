#! /usr/bin/env bash

nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix

echo -e "\nThe ISO can be found in result/iso.\n"

