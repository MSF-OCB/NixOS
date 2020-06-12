#! /usr/bin/env nix-shell
#! nix-shell -p nix-prefetch-git -i bash

# Takes the name of the repo (in the MSF-OCB organisation) as first param
# Takes the revision (commit hash) for which to calculate the hash as the second param
# Example:
#   ./prefetch_git.sh nixos_encryption_manager 36bb50d9

nix-prefetch-git --url "https://github.com/msf-ocb/${1}/" --rev "${2}"

