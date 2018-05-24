# Converting an existing system to NixOS

We don't need a swap partition since we use zram swap on NixOS, we'll thus delete the swap partition and add the extra space to the root partition.

Usually the swap device is in the LVM partition, use `lvdisplay` to identify it (and not down the root partition too), then run

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
nix-channel --add https://nixos.org/channels/nixos-18.03-small nixpkgs
nix-channel --update
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"
sudo `which nixos-generate-config` --root /
```

Edit `/etc/nixos/hardware-configuration.nix` and make sure that no swap device is mentionned and remove any spurious partitions left over from the previous Linux version (like `/var/lib/lxcfs`).

Next, run the steps from the README to download the NixOS config and put it in `/etc/nixos`. This is also the time to make any modifications to the config before we build it.

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

Reboot and you should end up in a NixOS system! The old contents of the root directory can be found at `/old_root/`.

Now follow the final steps of the general installation guide.
