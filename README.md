# Arch Linux


### Grub Theme

```bash
mkdir -p "/boot/grub/themes/CyberRe"
cp -a arch/CyberRe /boot/grub/themes/CyberRe
cp -an /etc/default/grub /etc/default/grub.bak

grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null
sed -i '/GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"/boot/grub/themes/CyberRe/theme.txt\"" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
```

### Yay

```bash
cd /tmp && git clone https://aur.archlinux.org/yay.git
cd /tmp/yay && makepkg -si --noconfirm
cd ~ && rm -rf /tmp/yay
```

### gnome-extension

```
yay -S --noconfirm --needed  chrome-gnome-shell gnome-shell-extension-dash-to-dock 
```

### powerlevel10k

```bash
yay -S --noconfirm --needed nerd-fonts-fira-code nordic-darker-standard-buttons-theme nordic-darker-theme nordic-theme 

touch .cache/zshhistory
mv arch/zsh .zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
ln -s ~/.zsh/zshrc .zshrc

chsh -s /usr/bin/zsh
```

### wine

```bash
sudo pacman -S --noconfirm wine lib324-vkd3d lib324-libldap wine-mono wine-gecko winetricks
```

<!-- 
The Windows .efi file

mkdir -p /mnt/EFI/Microsoft/Boot
cp /mnt/EFI/grub/grubx64.efi /mnt/EFI/Microsoft/Boot/bootmgfw.efi

EFI fallback .efi file (as defined in the EFI standard.)

mkdir -p /mnt/EFI/BOOT
cp /mnt/EFI/grub/grub64.efi /mnt/EFI/BOOT/bootx64.efi

https://www.xfce-look.org/p/1272122
sudo tar -xzvf ~/Downloads/sugar-dark.tar.gz -C /usr/share/sddm/themes
'/etc/sddm.conf/usr/lib/sddm/sddm.conf.d/sddm.conf'.

[Theme]
Current=sugar-candy

qt5-graphicaleffects
 -->

<!-- pacman -S gdm gnome-shell gnome-control-center gnome-tweak-tool -->
<!-- pacmam -S nautilus chromium -->
<!-- systemctl enable gdm.service -->




