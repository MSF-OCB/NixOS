#!/usr/bin/env bash
set -e

NIXOS_RELEASE="19-09"

# To install, run:
# curl -L https://github.com/msf-ocb/nixos/raw/master/install.sh | sudo bash -s <disk device> <host name> [<root partition size (GB)>]

DEVICE="$1"
TARGET_HOSTNAME="$2"
ROOT_SIZE="${3:-30}"

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

MP=$(mountpoint -q /mnt/; echo $?) || true
if [ "${MP}" -eq 0 ]; then
  echo "/mnt/ is mounted, unmount first!"
  exit 1
fi

cryptsetup close nixos_data_decrypted || true
vgremove -f LVMVolGroup || true
pvremove /dev/disk/by-partlabel/nixos_lvm || true

sgdisk -og "${DEVICE}"
sgdisk -n 1:2048:+512M -c 1:"efi" -t 1:ef00 "${DEVICE}"
sgdisk -n 2:0:+512M -c 2:"nixos_boot" -t 2:8300 "${DEVICE}"
sgdisk -n 3:0:0 -c 3:"nixos_lvm" -t 3:8e00 "${DEVICE}"
sgdisk -p "${DEVICE}"

for countdown in $( seq 60 -1 0 ); do
  if [ ! -b /dev/disk/by-partlabel/efi ] || [ ! -b /dev/disk/by-partlabel/nixos_boot ] || [ ! -b /dev/disk/by-partlabel/nixos_lvm ]; then
    echo "waiting for /dev/disk/by-partlabel to be populated ($countdown)"
    partprobe
    sleep 1
  else
    break
  fi
done
if [ ! -b /dev/disk/by-partlabel/efi ] || [ ! -b /dev/disk/by-partlabel/nixos_boot ] || [ ! -b /dev/disk/by-partlabel/nixos_lvm ]; then
  echo "/dev/disk/by-partlabel is missing devices..."
  ls -la /dev/disk/by-partlabel
  exit 1
fi
ls -l /dev/disk/by-partlabel/

pvcreate /dev/disk/by-partlabel/nixos_lvm
vgcreate LVMVolGroup /dev/disk/by-partlabel/nixos_lvm

lvcreate --yes -L "${ROOT_SIZE}"GB -n nixos_root LVMVolGroup
lvcreate --yes -l 100%FREE -n nixos_data LVMVolGroup

wipefs -a /dev/disk/by-partlabel/efi
mkfs.vfat -n EFI -F32 /dev/disk/by-partlabel/efi
wipefs -a /dev/disk/by-partlabel/nixos_boot
mkfs.ext4 -e remount-ro -L nixos_boot /dev/disk/by-partlabel/nixos_boot
mkfs.ext4 -e remount-ro -L nixos_root /dev/LVMVolGroup/nixos_root

for countdown in $( seq 60 -1 0 ) ; do
  if [ ! -b /dev/disk/by-label/EFI ] || [ ! -b /dev/disk/by-label/nixos_boot ] || [ ! -b /dev/disk/by-label/nixos_root ]; then
    echo "waiting for /dev/disk/by-label to be populated ($countdown)"
    partprobe
    sleep 1
  else
    break;
  fi
done
if [ ! -b /dev/disk/by-label/EFI ] || [ ! -b /dev/disk/by-label/nixos_boot ] || [ ! -b /dev/disk/by-label/nixos_root ]; then
  echo "/dev/disk/by-label is missing devices..."
  ls -la /dev/disk/by-label
  exit 1
fi

mount /dev/disk/by-label/nixos_root /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/nixos_boot /mnt/boot
mkdir -p /mnt/boot/efi
mount /dev/disk/by-label/EFI /mnt/boot/efi

rm -rf /mnt/etc/
nix-env -iA nixos.git
git clone https://github.com/msf-ocb/nixos.git /mnt/etc/nixos/
nixos-generate-config --root /mnt --no-filesystems

# Do this only after generating the hardware config
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
cryptsetup close nixos_data_decrypted

ln -s hosts/"${TARGET_HOSTNAME}".nix /mnt/etc/nixos/settings.nix

ssh-keygen -a 100 -t ed25519 -N "" -C "tunnel@${TARGET_HOSTNAME}" -f /mnt/etc/nixos/local/id_tunnel

nixos-install --no-root-passwd --max-jobs 4

nixos-enter --root /mnt/ -c "nix-channel --add https://nixos.org/channels/nixos-${NIXOS_RELEASE} nixos"

mv /tmp/keyfile /mnt/keyfile
chown root:root /mnt/keyfile
chmod 0600 /mnt/keyfile

echo -e "\nNixOS installation finished, please reboot using \"sudo systemctl reboot\""

echo -e "\nDo not forget to:"
echo    "  1. Set a recovery passphrase for the encrypted partition and add it to Keeper (see https://github.com/MSF-OCB/NixOS/wiki/Install-NixOS for the command)."
echo -e "  2. Upload the public tunnel key to GitHub.\n"

