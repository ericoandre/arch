# Arch Linux


### Visual Code Studio
```bash
wget "https://go.microsoft.com/fwlink/?LinkID=620885" -O vscode.tar.gz
sudo tar -vzxf vscode.tar.gz -C /opt/
sudo ln -sf /opt/VSCode-linux-x64/code /usr/bin/code
sudo echo -e '[Desktop Entry]\nVersion=1.0\nName=vscode\nExec=code\nIcon=/opt/VSCode-linux-x64/resources/app/resources/linux/code.png\nType=Application\nCategories=Development;Application' | sudo tee /usr/share/applications/vscode.desktop
```

### Sublime Text
```bash
wget https://download.sublimetext.com/sublime_text_3_build_3211_x64.tar.bz2 -O sublime_text.tar.bz2
sudo tar xjf sublime_text.tar.bz2 -C /opt/
sudo ln -sf /opt/sublime_text_3/sublime_text /usr/bin/sublime
sudo echo -e '[Desktop Entry]\nVersion=1.0\nName=sublime text 3\nExec=sublime\nIcon=/opt/sublime_text_3/Icon/256x256/sublime-text.png\nType=Application\nCategories=Development;Application' | sudo tee /usr/share/applications/sublime_text.desktop
```


### Eclipse
```bash
wget https://eclipse.mirror.rafal.ca/technology/epp/downloads/release/2020-12/R/eclipse-java-2020-12-R-linux-gtk-x86_64.tar.gz -O eclipse.tar.gz
sudo tar -vzxf eclipse.tar.gz -C /opt/
sudo ln -sf /opt/eclipse/eclipse /usr/bin/eclipse
sudo echo -e '[Desktop Entry]\nVersion=1.0\nName=Eclipse\nExec=eclipse\nTerminal=false\nIcon=/opt/eclipse/icon.xpm\nType=Application\nComment=Integrated Development Environment\nCategories=Development;Application;IDE' | sudo tee /usr/share/applications/eclipse.desktop
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
yay -S --noconfirm --needed nerd-fonts-fira-code nordic-darker-standard-buttons-theme nordic-darker-theme nordic-theme numix-themes

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




pacman -S pulseaudio pulseaudio-alsa pavucontrol gnome-terminal firefox flashplugin vlc chromium unzip unrar p7zip pidgin skype deluge smplayer audacious qmmp gimp xfburn thunderbird gedit gnome-system-monitor


pacman -S a52dec faac faad2 flac jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv wavpack x264 xvidcore gstreamer0.10-plugins


pacman -S libgtop







conky-lua-archers
arcolinux-conky-collection-git
arcolinux-pipemenus-git
yad
libpulse




    arch_chroot "pacman -S --noconfirm xorg xorg-server xorg-twm xorg-xclock xorg-xinit xterm xorg-fonts-100dpi xorg-fonts-75dpi alsa-firmware alsa-utils"

    case $desktop in
        1)
            DEpkg="gdm gnome-shell gnome-backgrounds gnome-control-center gnome-screenshot gnome-system-monitor gnome-terminal gnome-tweak-tool nautilus gedit gnome-calculator gnome-disk-utility eog evince"
            ;;
        2)
            DEpkg="gdm gnome gnome-tweak-tool"
            ;;
        3)
            DEpkg="sddm plasma plasma-wayland-session dolphin konsole kate kcalc ark gwenview spectacle okular packagekit-qt5"
            ;;
        4)
            DEpkg="lxdm xfce4 xfce4-goodies network-manager-applet"
            ;;
    esac








-->

<!-- pacman -S gdm gnome-shell gnome-control-center gnome-tweak-tool -->
<!-- pacmam -S nautilus chromium -->
<!-- systemctl enable gdm.service -->




