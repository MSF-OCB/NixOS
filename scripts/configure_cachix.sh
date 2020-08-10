#! /usr/bin/env nix-shell
#! nix-shell --packages cachix -i bash

modules_dir="$(dirname "${BASH_SOURCE}")/../modules/"

sudo cachix use -d "${modules_dir}" panic-button

mode="$(id -nu):$(id -ng)"
sudo chown -R "${mode}" "${modules_dir}/cachix/" "${modules_dir}/cachix.nix"

