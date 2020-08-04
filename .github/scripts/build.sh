#! /usr/bin/env bash

nixos_channel="${INPUT_NIXOS_CHANNEL}"
nixos_build_groups="${INPUT_NIXOS_BUILD_GROUPS:-1}"
nixos_build_group_id="${INPUT_NIXOS_BUILD_GROUP_ID:-1}"

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
group_id="${nixos_build_group_id}"

if [ "${group_id}" -gt "${group_amount}" ]; then
  echo "The build group ID (${group_id}) cannot exceed the number of build groups (${group_amount})."
  exit 1
fi
if [ "${group_id}" -le "0" ]; then
  echo "The build group ID (${group_id}) cannot be less than or equal to zero."
  exit 1
fi

# Every group will build the hosts from ((group_id - 1) * slice_size) until (group_id * slice_size)
slice_size=$(( ${length} / ${group_amount} ))
bgn="$(( (${group_id} - 1) * ${slice_size} ))"
if [ "${group_id}" -eq "${group_amount}" ]; then
  # For the last group, we need to include the hosts that would be forgotten due to integer divisions
  end="${length}"
else
  end="$(( ${bgn} + ${slice_size} ))"
fi
# Arrays are sliced by specifying the begin index and the amount of elements to take
amount="$(( ${end} - ${bgn} ))"

print_banner "Build group ${group_id}, building hosts ${bgn} until ${end}."

for host in ${hosts[@]:${bgn}:${amount}}; do
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

