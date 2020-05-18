#! /usr/bin/env sh

nix-channel --add https://nixos.org/channels/nixos-20.03 nixpkgs
nix-channel --update

# If we are not running in a github action, we need to clone the repo ourselves
if [ -z "$(ls -A ." ]; then
  dir="/nixos_repo"
  nix-shell --packages git --run "git clone https://github.com/msf-ocb/nixos ${dir}"
else
  dir="."
fi

touch "${dir}/local/id_tunnel"
echo '{}' > "${dir}/hardware-configuration.nix"

for host in ${NIXOS_BUILD_HOSTS:-$(ls ${dir}/org-spec/hosts)}; do
  if [ -L "${dir}/settings.nix" ]; then
    unlink "${dir}/settings.nix"
  fi
  ln -s "${dir}/org-spec/hosts/${host}" "${dir}/settings.nix"
  nix-build '<nixpkgs/nixos>' -I nixos-config="${dir}/configuration.nix" -A system
  if [ "${?}" != "0" ]; then
    echo "Build failed: ${host}"
    exit 1
  fi
done

