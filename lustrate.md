We don't need a swap partition since we use zram swap on NixOS, we'll thus delete the swap partition and add the extra space to the root partition.

Usually the swap device is in the LVM partition, use `lvdisplay` to identify it (and not down the root partition too), then run

```
sudo swapoff <swap device>
sudo lvremove <swap device>
sudo lvextend -l 100%FREE <root device>
sudo resize2fs <root device>
```

Then we'll follow the steps from [here](https://nixos.org/nixos/manual/index.html#sec-installing-from-other-distro):

```
bash <(curl https://nixos.org/nix/install)
. $HOME/.nix-profile/etc/profile.d/nix.sh
nix-channel --add https://nixos.org/channels/nixos-18.03-small nixpkgs
nix-channel --update
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"
sudo `which nixos-generate-config` --root /
```

Run the steps from the README to download the NixOS config and put it in `/etc/nixos`.

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
