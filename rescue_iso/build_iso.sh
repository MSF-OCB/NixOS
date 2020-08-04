#! /usr/bin/env bash

iso_dir="$(dirname "${BASH_SOURCE}")"

nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage \
                            -I nixos-config="${iso_dir}/iso.nix"

if [ "${?}" -eq "0" ]; then
  echo -e "\nThe ISO can be found in result/iso.\n"
else
  exit 1
fi

