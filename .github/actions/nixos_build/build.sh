#! /usr/bin/env sh

nix-channel --add https://nixos.org/channels/nixos-20.03 nixpkgs
nix-channel --update

nix-shell --packages git --run "git clone https://github.com/msf-ocb/nixos nixos_repo"

touch /nixos_repo/local/id_tunnel
echo '{}' > /nixos_repo/hardware-configuration.nix

for host in $(ls /nixos_repo/org-spec/hosts); do
  if [ -L /nixos_repo/settings.nix ]; then
    unlink /nixos_repo/settings.nix
  fi
  ln -s /nixos_repo/org-spec/hosts/${host} /nixos_repo/settings.nix
  nix-build '<nixpkgs/nixos>' -I nixos-config=/nixos_repo/configuration.nix -A system
  if [ "${?}" != "0" ]; then
    echo "Build failed: ${host}"
    exit 1
  fi
done

