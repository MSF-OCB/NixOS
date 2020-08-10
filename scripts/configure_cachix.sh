#! /usr/bin/env nix-shell
#! nix-shell --packages cachix -i bash

scripts_dir="$(dirname "${BASH_SOURCE}")"

sudo cachix use -d "${scripts_dir}/.." panic-button

mode="$(id -nu):$(id -ng)"
sudo chown -R "${mode}" cachix/ cachix.nix

