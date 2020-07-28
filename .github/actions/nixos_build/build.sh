#! /usr/bin/env sh

nixos_channel=${NIXOS_CHANNEL:-'nixos-20.03'}

nix-channel --add https://nixos.org/channels/${nixos_channel} nixpkgs
nix-channel --update

# If we are not running in a github action, we need to clone the repo ourselves
if [ -f "configuration.nix" ]; then
  dir="."
else
  dir="/nixos_repo"
  nix-shell --packages git --run "git clone https://github.com/msf-ocb/nixos ${dir}"
fi

touch "${dir}/local/id_tunnel"
echo '{}' > "${dir}/hardware-configuration.nix"


function print_banner() (
  msg="${1}"
  star_length=70
  stars="$(printf %-${star_length}s '' | tr ' ' '*')"

  function print_line() {
    _msg="${1}"

    echo "$(printf %-$((star_length - 1))s "* ${_msg}" '*')"
  }

  echo
  echo -e "\n${stars}"
  print_line ""
  print_line "${msg}"
  print_line ""
  echo -e "${stars}\n"
)

for host in ${NIXOS_BUILD_HOSTS:-$(ls ${dir}/org-spec/hosts)}; do

  print_banner "Building config: ${host}"

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

