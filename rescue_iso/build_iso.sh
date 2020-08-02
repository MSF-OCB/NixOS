#! /usr/bin/env bash

nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix

if [ "${?}" -eq "0" ]; then
  echo -e "\nThe ISO can be found in result/iso.\n"
fi

