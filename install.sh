#!/usr/bin/env bash
set -e

# To install, run:
# curl -L https://github.com/msf-ocb/nixos/raw/master/install.sh | sudo bash -s -- -d <disk device> -h <host name>

function wait_for_devices() {
  arr=("${@}")
  devs="${arr[@]}"
  all_found=false
  for dev in ${devs}; do
    udevadm settle --exit-if-exists=${dev}
  done
  for countdown in $( seq 60 -1 0 ); do
    missing=false
    for dev in ${devs}; do
      if [ ! -b ${dev} ]; then
        missing=true
        echo "waiting for ${dev}... (${countdown})"
      fi
    done
    if [ "${missing}" = true ]; then
      partprobe ${DEVICE}
      sleep 1
      for dev in ${devs}; do
        udevadm settle --exit-if-exists=${dev}
      done
    else
      all_found=true
      break;
    fi
  done
  if [ "${all_found}" != true ]; then
    echo "Time-out waiting for devices."
    exit 1
  fi
}

function exit_usage() {
  cat <<EOF
Usage:
  install.sh -d <device> -h <hostname> [-r <root size (GB)>] [-l] [-D]
    -l triggers legacy installation mode instead of UEFI
    -D causes the creation of an encrypted data partition to be skipped
EOF
  exit 1
}

function exit_missing_arg() {
  echo "Error: -${1} requires an argument"
  exit_usage
}

while getopts ':d:h:r:lD' flag; do
  case "${flag}" in
    d  )
      if [[ "${OPTARG}" =~ ^-. ]]; then
        OPTIND=$OPTIND-1
      else
        DEVICE="${OPTARG}"
      fi
      if [[ -z "${DEVICE}" ]]; then
        exit_missing_arg "${flag}"
      fi
      ;;
    h  )
      if [[ "${OPTARG}" =~ ^-. ]]; then
        OPTIND=$OPTIND-1
      else
        TARGET_HOSTNAME="${OPTARG}"
      fi
      if [[ -z "${TARGET_HOSTNAME}" ]]; then
        exit_missing_arg "${flag}"
      fi
      ;;
    r  )
      if [[ "${OPTARG}" =~ ^-. ]]; then
        OPTIND=$OPTIND-1
      else
        ROOT_SIZE="${OPTARG}"
      fi
      if [[ -z "${ROOT_SIZE}" ]]; then
        exit_missing_arg "${flag}"
      fi
      ;;
    l  )
      USE_UEFI=false
      ;;
    D  )
      CREATE_DATA_PART=false
      ;;
    :  )
      exit_missing_arg "${OPTARG}"
      ;;
    \? )
      echo "Invalid option: -${OPTARG}"
      exit_usage
      ;;
    *  )
      exit_usage
      ;;
  esac
done

ROOT_SIZE="${ROOT_SIZE:-25}"
USE_UEFI="${USE_UEFI:=true}"
CREATE_DATA_PART="${CREATE_DATA_PART:=true}"

swapfile="/mnt/swapfile"
main_repo="git@github.com:MSF-OCB/NixOS.git"
config_repo="git@github.com:MSF-OCB/NixOS-OCB-config.git"

if [ $EUID -ne 0 ]; then
  echo "Error this script should be run using sudo or as the root user"
  exit 1
fi

if [ -z "${DEVICE}" ] || [ -z "${TARGET_HOSTNAME}" ]; then
  if [ -z "${DEVICE}" ]; then
    echo "Error: no installation device specified"
  elif [ -z "${TARGET_HOSTNAME}" ]; then
    echo "Error: no target hostname specified"
  fi
  exit_usage
fi

if [[ ! ${ROOT_SIZE} =~ ^[0-9]+$ ]]; then
  "Error: invalid root size specified (${ROOT_SIZE})"
  exit_usage
fi
disk_size="$(($(blockdev --getsize64 "${DEVICE}")/1024/1024/1024 - 2))"
if [ "${ROOT_SIZE}" -gt "${disk_size}" ]; then
  echo "Error: root size bigger than the provided device, please specify a smaller root size."
  exit_usage
fi

if [ "${USE_UEFI}" = true ] && [ ! -d "/sys/firmware/efi" ]; then
  echo "ERROR: installing in UEFI mode but we are currently booted in legacy mode."
  echo "Please check:"
  echo "  1. That your BIOS is configured to boot using UEFI only."
  echo "  2. That the hard disk that you booted from (usb key or hard drive) is using the GPT format and has a valid ESP."
  echo "And reboot the system in UEFI mode. Alternatively you can run this installer in legacy mode."
  exit 1
fi

if [ ! -f "/tmp/id_tunnel" ] || [ ! -f "/tmp/id_tunnel.pub" ]; then
  echo "Generating a new SSH key pair for this host..."
  ssh-keygen -a 100 \
             -t ed25519 \
             -N "" \
             -C "tunnel@${TARGET_HOSTNAME}" \
             -f /tmp/id_tunnel
  echo "SSH keypair generated."
fi

# Check whether we can authenticate to GitHub using this server's key
(
  set +e
  nix-shell --packages git --run "git -c core.sshCommand='ssh -i /tmp/id_tunnel' \
                                      ls-remote ${config_repo} \
                                      2>$1 > /dev/null"
  retval="${?}"
  if [ "${retval}" -ne "0" ]; then
    echo -e "\nThe SSH key in /tmp/id_tunnel, does not give us access to GitHub."
    echo    "Please add the public key (/tmp/id_tunnel.pub) to"
    echo    "the tunnels.json file in the NixOS-OCB-config repo."
    echo    "To view the key and copy it, run: \"cat /tmp/id_tunnel.pub\""
    echo -e "\nYou can restart the installer once this is done and"
    echo -e "the GitHub deployment actions have run.\n"
    echo    "If you want me to generate a new key pair instead,"
    echo    "then remove /tmp/id_tunnel and /tmp/id_tunnel.pub"
    echo    "and restart the installer."
    echo    "You will then see this message again,"
    echo    "and you will need to add the newly generated key to GitHub."
  fi
  exit ${retval}
)

detect_swap="$(swapon | grep "${swapfile}" > /dev/null 2>&1; echo $?)"
if [ "${detect_swap}" -eq 0 ]; then
  swapoff "${swapfile}"
  rm --force "${swapfile}"
fi

MP=$(mountpoint --quiet /mnt/; echo $?) || true
if [ "${MP}" -eq 0 ]; then
  umount -R /mnt/
fi

cryptsetup close nixos_data_decrypted || true
vgremove --force LVMVolGroup || true
# If the existing partition table is GPT, we use the partlabel
pvremove /dev/disk/by-partlabel/nixos_lvm || true
# If the existing partition table is MBR, we need to use direct addressing
pvremove "${DEVICE}2" || true

if [ "${USE_UEFI}" = true ]; then
  # Using zeroes for the start and end sectors, selects the default values, i.e.:
  #   the next unallocated sector for the start value
  #   the last sector of the device for the end value
  sgdisk --clear --mbrtogpt "${DEVICE}"
  sgdisk --new=1:2048:+512M --change-name=1:"efi"        --typecode=1:ef00 "${DEVICE}"
  sgdisk --new=2:0:+512M    --change-name=2:"nixos_boot" --typecode=2:8300 "${DEVICE}"
  sgdisk --new=3:0:0        --change-name=3:"nixos_lvm"  --typecode=3:8e00 "${DEVICE}"
  sgdisk --print "${DEVICE}"

  wait_for_devices "/dev/disk/by-partlabel/efi" \
                   "/dev/disk/by-partlabel/nixos_boot" \
                   "/dev/disk/by-partlabel/nixos_lvm"
else
  sfdisk --wipe            always \
         --wipe-partitions always \
         "${DEVICE}" \
<<EOF
label: dos
unit:  sectors

# Boot partition
type=83, start=2048, size=512MiB, bootable

# LVM partition, from first unallocated sector to end of disk
# These start and size values are the defaults when nothing is specified
type=8e
EOF
fi

if [ "${USE_UEFI}" = true ]; then
  BOOT_PART="/dev/disk/by-partlabel/nixos_boot"
  LVM_PART="/dev/disk/by-partlabel/nixos_lvm"
else
  BOOT_PART="${DEVICE}1"
  LVM_PART="${DEVICE}2"
fi

wait_for_devices "/dev/disk/by-partlabel/nixos_lvm"
pvcreate "${LVM_PART}"
wait_for_devices "/dev/disk/by-partlabel/nixos_lvm"
vgcreate LVMVolGroup "${LVM_PART}"
lvcreate --yes --size "${ROOT_SIZE}"GB --name nixos_root LVMVolGroup
wait_for_devices "/dev/LVMVolGroup/nixos_root"

if [ "${USE_UEFI}" = true ]; then
  wipefs --all /dev/disk/by-partlabel/efi
  mkfs.vfat -n EFI -F32 /dev/disk/by-partlabel/efi
fi
wipefs --all "${BOOT_PART}"
mkfs.ext4 -e remount-ro -L nixos_boot "${BOOT_PART}"
mkfs.ext4 -e remount-ro -L nixos_root /dev/LVMVolGroup/nixos_root

if [ "${USE_UEFI}" = true ]; then
  wait_for_devices "/dev/disk/by-label/EFI"
fi
wait_for_devices "/dev/disk/by-label/nixos_boot" \
                 "/dev/disk/by-label/nixos_root"

mount /dev/disk/by-label/nixos_root /mnt
mkdir --parents /mnt/boot
mount /dev/disk/by-label/nixos_boot /mnt/boot
if [ "${USE_UEFI}" = true ]; then
  mkdir --parents /mnt/boot/efi
  mount /dev/disk/by-label/EFI /mnt/boot/efi
fi

fallocate -l 2G "${swapfile}"
chmod 0600 "${swapfile}"
mkswap "${swapfile}"
swapon "${swapfile}"

rm --recursive --force /mnt/etc/
nix-shell --packages git --run "git -c core.sshCommand='ssh -i /tmp/id_tunnel' \
                                    clone ${main_repo} \
                                    /mnt/etc/nixos/"
nix-shell --packages git --run "git -c core.sshCommand='ssh -i /tmp/id_tunnel' \
                                    clone ${config_repo} \
                                    /mnt/etc/nixos/ocb-config"
nixos-generate-config --root /mnt --no-filesystems
ln --symbolic ocb-config/hosts/"${TARGET_HOSTNAME}".nix /mnt/etc/nixos/settings.nix
cp /tmp/id_tunnel /tmp/id_tunnel.pub /mnt/etc/nixos/local/

if [ "${CREATE_DATA_PART}" = true ]; then
  # Do this only after generating the hardware config
  lvcreate --yes --extents 100%FREE --name nixos_data LVMVolGroup
  wait_for_devices "/dev/LVMVolGroup/nixos_data"

  dd bs=512 count=4 if=/dev/urandom of=/mnt/keyfile
  chown root:root /mnt/keyfile
  chmod 0400 /mnt/keyfile

  mkdir -p /run/cryptsetup
  cryptsetup --verbose \
             --batch-mode \
             --cipher aes-xts-plain64 \
             --key-size 512 \
             --hash sha512 \
             --use-urandom \
             luksFormat \
             --type luks2 \
             --key-file /mnt/keyfile \
             /dev/LVMVolGroup/nixos_data
  cryptsetup open \
             --key-file /mnt/keyfile \
             /dev/LVMVolGroup/nixos_data nixos_data_decrypted
  mkfs.ext4 -e remount-ro \
            -m 1 \
            -L nixos_data \
            /dev/mapper/nixos_data_decrypted

  wait_for_devices "/dev/disk/by-label/nixos_data"

  mkdir --parents /mnt/opt
  mount /dev/disk/by-label/nixos_data /mnt/opt
  mkdir --parents /mnt/home
  mkdir --parents /mnt/opt/.home
  mount --bind /mnt/opt/.home /mnt/home
fi

nixos-install --no-root-passwd --max-jobs 4

swapoff "${swapfile}"
rm -f "${swapfile}"

if [ "${CREATE_DATA_PART}" = true ]; then
  umount -R /mnt/home
  umount -R /mnt/opt
  cryptsetup close nixos_data_decrypted
fi

echo -e "\nNixOS installation finished, please reboot using \"sudo systemctl reboot\""

echo -e "\nDo not forget to set a recovery passphrase for the encrypted partition and add it to Keeper
echo -e "see https://github.com/MSF-OCB/NixOS/wiki/Install-NixOS for the command."

