#! /usr/bin/env nix-shell
#! nix-shell --packages cachix -i bash

modules_dir="$(dirname "${BASH_SOURCE}")/../modules/"

cachix use -m nixos -d "${modules_dir}" panic-button

