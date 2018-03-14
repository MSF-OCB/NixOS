# NixOS
NixOS config for servers in the field

[(LVM reference.)](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations)

Use `fdisk` to create partitions, you can list all devices with `fdisk -l` and then run `fdisk <device>` to configure a particular drive.

1. boot partition 1 GB, type 83 (Linux);
2. LVM partition for the rest of the drive, type 8e (Linux LVM);
3. Full drive LVM partition for any extra drives.

Create a physical volume for every LVM partition using

```pvcreate <partition>```

Create a volume group containing all volumes using

```vgcreate LVMVolGroup <device 1> ... <device n>```

Create a single root partition on the LVM volume using

```lvcreate -l 100%FREE -n nixos_root LVMVolGroup```

Create filesystems:

```
mkfs.ext4 -L nixos_boot /dev/<boot partition>
mkfs.ext4 -L nixos_root /dev/LVMVolGroup/nixos_root
```

[(NixOS installation manual)](https://nixos.org/nixos/manual/index.html#sec-installation)

```
mount /dev/disk/by-label/nixos_root /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/nixos_boot /mnt/boot
nixos-generate-config --root /mnt
curl -L https://github.com/MSF-OCB/NixOS/archive/master.zip --output /tmp/config.zip
cd /tmp
unzip config.zip
mv NixOS-master/* /mnt/etc/nixos
mv NixOS-master/.gitignore /mnt/etc/nixos
rmdir NixOS-master # Verify it's empty now
cp /mnt/etc/nixos/settings.nix.template /mnt/etc/nixos/settings.nix
```

```
nano /mnt/etc/nixos/settings.nix
```

```
nixos-install
```

To find a stable device name for grub:

```
ls -l /dev/disk/by-id/ | grep "wwn.*<device>$"
```

Boot into the OS

Check that we are on the correct nix channel

```
sudo nix-channel --list
```

This should show the 17.09 channel with name `nixos`, otherwise we need to add it

```
sudo nix-channel --add https://nixos.org/channels/nixos-17.09 nixos
```

Run

```
sudo nixos-rebuild switch --upgrade
```

Generate the ssh key for the reverse tunnel

```
sudo -u tunnel ssh-keygen -t ecdsa -b 521 -N "" -C "$(whoami)@${HOSTNAME}" -f ${HOME}/id_${HOSTNAME}
```
