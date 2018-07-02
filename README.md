# NixOS
NixOS config for servers in the field.

1. [Installing NixOS from scratch](#installing-nixos-from-scratch)
2. [Converting an existing Linux system into NixOS](#converting-an-existing-linux-system-into-nixos)

## Method 1: Installing NixOS from scratch

### Setting up filesystems

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

### Installing the OS

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

And if you enabled the reverse tunnel service, generate a key pair for the tunnel:
```
sudo ssh-keygen -a 100 -t ed25519 -N "" -C "tunnel@${HOSTNAME}" -f /etc/nixos/local/id_tunnel
```
if the reverse tunnel service is enabled in settings.nix but the private key is not present, the build will fail and complain that the file cannot be found.

Then launch the installer:
```
nixos-install --no-root-passwd --max-jobs 4
```
*Note down the current IP address*, this will allow you to connect via ssh in a bit, use `ip addr` to find the current address.

Then, reboot, remove the usb drive and boot into the new OS.

### Final steps after booting the OS

You should now be able to connect to the newly installed system with ssh, using the local IP address which you noted down before the reboot.

First check that we are on the correct nix channel
```
sudo nix-channel --list
```
This should show the 18.03 channel with name `nixos`, otherwise we need to add it
```
sudo nix-channel --add https://nixos.org/channels/nixos-18.03 nixos
```

Then we will do a full system update
```
sudo nixos-rebuild switch --upgrade
```

If you just upgraded from an existing Linux system, it's safer to reinstall the bootloader once more to avoid issues
```
sudo nixos-rebuild switch --upgrade --install-bootloader
```

Next, if not already done, we'll put the content of the *public* key file for the reverse tunnel (`/etc/nixos/local/id_tunnel.pub`) in the `authorized_keys` file for the tunnel user on github (this repo, `keys/tunnel`). (Easiest way is to connect via SSH on the local network to copy the key.)
Then do a `git pull` and a rebuild of the config on the ssh relay servers.

Finally, we will turn `/etc/nixos` into a git clone of this repository
```
git init
git remote add origin https://github.com/MSF-OCB/NixOS
git fetch
git checkout --force --track origin/master  # Force to overwrite local files
git pull --rebase
```
Check with `git status` that there are no left-over untracked files, these should probably be either deleted or commited.

You're all done!

---

## Method 2: Converting an existing Linux system into NixOS

We don't need a swap partition since we use zram swap on NixOS, we'll thus delete the swap partition and add the extra space to the root partition.

Usually the swap device is in the LVM partition, use `lvdisplay` to identify it (and note down the root partition too), then run

```
sudo swapoff <swap device>
sudo lvremove <swap device>
sudo lvextend -l 100%FREE <root device>
sudo resize2fs <root device>
```
Set labels for the partitions
```
sudo e2label <root device> nixos_root
sudo e2label <boot device> nixos_boot
```
We'll also convert the boot partition from ext2 to ext4 (if needed)
```
sudo umount /boot/
sudo tune2fs -O extents,uninit_bg,dir_index,has_journal /dev/disk/by-label/nixos_boot
sudo fsck.ext4 -vf /dev/disk/by-label/nixos_boot
```

Change the filesystem type in `/etc/fstab` and remount with `mount -a`.

Then we'll follow the steps from [here](https://nixos.org/nixos/manual/index.html#sec-installing-from-other-distro):

```
bash <(curl https://nixos.org/nix/install)
. $HOME/.nix-profile/etc/profile.d/nix.sh
nix-channel --add https://nixos.org/channels/nixos-18.03 nixpkgs
nix-channel --update
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"
sudo `which nixos-generate-config` --root /
```

Edit `/etc/nixos/hardware-configuration.nix` and make sure that no swap device is mentionned and remove any spurious partitions left over from the previous Linux version (like `/var/lib/lxcfs`).

Next, run the steps to download the NixOS config from [this section](#installing-the-os) (but do not run the installer as instructed there!!) and put the config in `/etc/nixos`. Note that we are not mounting the filesystem under `/mnt/` here but working directly in `/etc/`. This is also the time to make any modifications to the config before we build it.

Then we'll go ahead and built the final NixOS system and setup the necessary files to have the conversion done on the next boot.
```
nix-env -p /nix/var/nix/profiles/system -f '<nixpkgs/nixos>' -I nixos-config=/etc/nixos/configuration.nix -iA system
sudo chown -R 0.0 /nix/
sudo chmod 1777 /nix/var/nix/profiles/per-user/
sudo chmod 1777 /nix/var/nix/gcroots/per-user/
sudo touch /etc/NIXOS
echo etc/nixos | sudo tee -a /etc/NIXOS_LUSTRATE
sudo mkdir /boot_old
sudo mv -v /boot/* /boot_old/
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot
```
*Note down the current IP address*, this will allow you to connect via ssh in a bit, use `ip addr` to find the current address.

*!!Very important!!*
If you are converting a system to which you do not have direct ssh access and which can only be accessed via a tunnel, you need to make sure that the tunnel service will work after the reboot!

To do so, make sure that the private key to log on to the ssh relay is already present at `/etc/nixos/local/id_tunnel` at this point and that the corresponding public key is enabled on the relay servers.
*!!Verify this very carefully, otherwise you will lock yourself out of the system!!*

Reboot and you should end up in a NixOS system! The old contents of the root directory can be found at `/old_root/`.

Now follow [the final steps of the general installation guide](#final-steps-after-booting-the-os).
