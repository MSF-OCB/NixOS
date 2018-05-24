# NixOS
NixOS config for servers in the field

## Setting up filesystems

[(LVM reference.)](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations)

Use `fdisk` to create partitions, you can list all devices with `fdisk -l` and then run `fdisk <device>` to configure a particular drive.

1. boot partition 1 GB, type 83 (Linux);
2. LVM partition for the rest of the drive, type 8e (Linux LVM);
3. Full drive LVM partition for any extra drives.

(Use the `m` function to see the commands. Use `n` to create a new partition and choose `+1G` for the size for `boot` and the default option of "rest of the disk" for the root partition. Then use `t` to change the type of the root partition and `w` to write the changes.)

Create a physical volume for every LVM partition using
```pvcreate <partition>```
Create a volume group containing all volumes using
```vgcreate LVMVolGroup <partition 1> ... <partition n>```
Create a single root partition on the LVM volume using
```lvcreate -l 100%FREE -n nixos_root LVMVolGroup```

Create filesystems:
```
mkfs.ext4 -L nixos_boot /dev/<boot partition>
mkfs.ext4 -L nixos_root /dev/LVMVolGroup/nixos_root
```

## Installing the OS

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

To find a stable device name for grub and append it to the settings file for copy/paste:
```
ls -l /dev/disk/by-id/ | grep "wwn.*<device>$" | tee -a /mnt/etc/nixos/settings.nix
```
Then you can add the path to the `grub.device` setting.

Set the required settings:
```
nano /mnt/etc/nixos/settings.nix
```

And then launch the installer:
```
nixos-install --no-root-passwd --max-jobs 4
```
Reboot, remove the usb drive and boot into the OS.

## Final steps after booting the OS

Check that we are on the correct nix channel
```
sudo nix-channel --list
```
This should show the 18.03-small channel with name `nixos`, otherwise we need to add it
```
sudo nix-channel --add https://nixos.org/channels/nixos-18.03-small nixos
```
Run
```
sudo nixos-rebuild switch --upgrade
```

Generate the ssh key for the reverse tunnel
```
sudo -u tunnel sh -c 'ssh-keygen -a 100 -t ed25519 -N "" -C "$(whoami)@${HOSTNAME}" -f ${HOME}/id_${HOSTNAME}'
```
and put the content of the public key file (`/var/tunnel/id_${HOSTNAME}`) in the `authorized_keys` file for the tunnel user on fictappmonitoring.msf.org (`/home/tunnel/.ssh/authorized_keys`). (Easiest way is to connect via SSH on the local network to copy the key.)

Finally, we will turn `/etc/nixos` into a git clone of this repository
```
git init
git remote add origin https://github.com/MSF-OCB/NixOS
git fetch
git checkout --force --track origin/master  # Force to overwrite local files
git pull --rebase
```
Check with `git status` that there are no left-over untracked files, these should probably be either deleted or commited.
