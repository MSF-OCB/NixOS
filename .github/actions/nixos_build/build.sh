#! /usr/bin/env bash

if [ -z "${INPUT_NIXOS_CHANNEL}" ]; then
  echo "Please set the INPUT_NIXOS_CHANNEL environment variable"
  echo "to specify the nixos channel."
  echo 'Example value: "nixos-20.03".'
  exit 1
fi

nixos_channel="${INPUT_NIXOS_CHANNEL}"
nixos_build_groups="${INPUT_NIXOS_BUILD_GROUPS:-1}"
nixos_build_group_id="${INPUT_NIXOS_BUILD_GROUP_ID:-1}"

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

declare -a hosts
hosts=($(ls ${dir}/org-spec/hosts | tr " " "\n"))
length=${#hosts[@]}

group_amount="${nixos_build_groups}"
group="${nixos_build_group_id}"

if [ "${group}" -gt "${group_amount}" ]; then
  echo "The build group ID (${group}) cannot exceed the number of build groups (${group_amount})."
  exit 1
fi

slice_size=$(( ${length} / ${group_amount} ))
bgn="$(( (${group} - 1) * ${slice_size} ))"
# We need to collect the hosts that would be forgotten due to integer divisions
if [ "${group}" -eq "${group_amount}" ]; then
  end="$(( ${length} ))"
else
  end="$(( ${bgn} + ${slice_size} ))"
fi

print_banner "Build group: ${group}; building hosts ${bgn} until ${end}."

for host in ${hosts[@]:${bgn}:${end}}; do
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

