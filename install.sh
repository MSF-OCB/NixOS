#!/usr/bin/env bash
set -e

# To install, run:
# curl -L https://github.com/msf-ocb/nixos/raw/master/install.sh | sudo bash -s <disk device> <host name> [<root partition size (GB)>]

function wait_for_devices() {
  arr=("$@")
  devs="${arr[@]}"
  all_found=false
  for countdown in $( seq 60 -1 0 ); do
    missing=false
    for dev in ${devs}; do
      if [ ! -b ${dev} ]; then
        missing=true
        echo "waiting for ${dev}... ($countdown)"
      fi
    done
    if ${missing}; then
      partprobe
      sleep 1
      for dev in ${devs}; do
        udevadm settle --exit-if-exists=${dev}
      done
    else
      all_found=true
      break;
    fi
  done
  if ! ${all_found}; then
    echo "Time-out waiting for devices."
    exit 1
  fi
}

CONFIG_REPO="https://github.com/msf-ocb/nixos.git"

DEVICE="$1"
TARGET_HOSTNAME="$2"
ROOT_SIZE="${3:-25}"

if [ -z ${CREATE_DATA_PART} ]; then
  CREATE_DATA_PART=true
fi

if [ -z "${DEVICE}" ] || [ -z "${TARGET_HOSTNAME}" ]; then
  echo "Usage: install.sh <disk device> <host name> [<root partition size (GB)>]"
  exit 1
fi

if [ $EUID -ne 0 ]; then
  echo "This script should be run using sudo or as the root user"
  exit 1
fi

if [ "${ROOT_SIZE}" -gt $(($(blockdev --getsize64 "${DEVICE}")/1024/1024/1024 - 2)) ]; then
  echo "Root size bigger than the provided device, please specify a smaller root size."
  echo "Usage: install.sh <disk device> <host name> [<root partition size (GB)>]"
  exit 1
fi

MP=$(mountpoint --quiet /mnt/; echo $?) || true
if [ "${MP}" -eq 0 ]; then
  echo "/mnt/ is mounted, unmount first!"
  exit 1
fi

cryptsetup close nixos_data_decrypted || true
vgremove --force LVMVolGroup || true
pvremove /dev/disk/by-partlabel/nixos_lvm || true

# Using zeroes for the start and end sectors, selects the default values, i.e.:
#   the next unallocated sector for the start value
#   the last sector of the device for the end value
sgdisk --clear --mbrtogpt "${DEVICE}"
sgdisk --new=1:2048:+512M --change-name=1:"efi"        --typecode=1:ef00 "${DEVICE}"
sgdisk --new=2:0:+512M    --change-name=2:"nixos_boot" --typecode=2:8300 "${DEVICE}"
sgdisk --new=3:0:0        --change-name=3:"nixos_lvm"  --typecode=3:8e00 "${DEVICE}"
sgdisk --print "${DEVICE}"

wait_for_devices "/dev/disk/by-partlabel/efi" "/dev/disk/by-partlabel/nixos_boot" "/dev/disk/by-partlabel/nixos_lvm"

pvcreate /dev/disk/by-partlabel/nixos_lvm
vgcreate LVMVolGroup /dev/disk/by-partlabel/nixos_lvm

lvcreate --yes --size "${ROOT_SIZE}"GB --name nixos_root LVMVolGroup
wait_for_devices "/dev/LVMVolGroup/nixos_root"

wipefs --all /dev/disk/by-partlabel/efi
mkfs.vfat -n EFI -F32 /dev/disk/by-partlabel/efi
wipefs --all /dev/disk/by-partlabel/nixos_boot
mkfs.ext4 -e remount-ro -L nixos_boot /dev/disk/by-partlabel/nixos_boot
mkfs.ext4 -e remount-ro -L nixos_root /dev/LVMVolGroup/nixos_root

wait_for_devices "/dev/disk/by-label/EFI" "/dev/disk/by-label/nixos_boot" "/dev/disk/by-label/nixos_root"

mount /dev/disk/by-label/nixos_root /mnt
mkdir --parents /mnt/boot
mount /dev/disk/by-label/nixos_boot /mnt/boot
mkdir --parents /mnt/boot/efi
mount /dev/disk/by-label/EFI /mnt/boot/efi

rm --recursive --force /mnt/etc/
nix-shell --packages git --run "git clone ${CONFIG_REPO} /mnt/etc/nixos/"
nixos-generate-config --root /mnt --no-filesystems
ln --symbolic hosts/"${TARGET_HOSTNAME}".nix /mnt/etc/nixos/settings.nix
ssh-keygen -a 100 -t ed25519 -N "" -C "tunnel@${TARGET_HOSTNAME}" -f /mnt/etc/nixos/local/id_tunnel

if [ ${CREATE_DATA_PART} = true ]; then
  # Do this only after generating the hardware config
  lvcreate --yes --extents 100%FREE --name nixos_data LVMVolGroup
  wait_for_devices "/dev/LVMVolGroup/nixos_data"

  dd bs=512 count=4 if=/dev/urandom of=/tmp/keyfile
  chown root:root /tmp/keyfile
  chmod 0600 /tmp/keyfile

  cryptsetup --verbose \
             --batch-mode \
             --cipher aes-xts-plain64 \
             --key-size 512 \
             --hash sha512 \
             --use-random \
             luksFormat \
             --type luks2 \
             --key-file /tmp/keyfile \
             /dev/LVMVolGroup/nixos_data
  cryptsetup open --key-file /tmp/keyfile /dev/LVMVolGroup/nixos_data nixos_data_decrypted
  mkfs.ext4 -e remount-ro -m 1 -L nixos_data /dev/mapper/nixos_data_decrypted

  wait_for_devices "/dev/disk/by-label/nixos_data"

  mkdir --parents /mnt/opt
  mount /dev/disk/by-label/nixos_data /mnt/opt
  mkdir --parents /mnt/home
  mkdir --parents /mnt/opt/.home
  mount --bind /mnt/opt/.home /mnt/home
fi

nixos-install --no-root-passwd --max-jobs 4

if [ ${CREATE_DATA_PART} = true ]; then
  umount /mnt/home
  umount /mnt/opt
  cryptsetup close nixos_data_decrypted

  mv /tmp/keyfile /mnt/keyfile
  chown root:root /mnt/keyfile
  chmod 0600 /mnt/keyfile
fi

echo -e "\nNixOS installation finished, please reboot using \"sudo systemctl reboot\""

echo -e "\nDo not forget to:"
echo    "  1. Set a recovery passphrase for the encrypted partition and add it to Keeper (see https://github.com/MSF-OCB/NixOS/wiki/Install-NixOS for the command)."
echo -e "  2. Upload the public tunnel key to GitHub.\n"

