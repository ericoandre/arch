# Arch Linux

Instalador Modo auto BIOS/UEFI, com opcao de instalar  em hd sem particao.

### Visual Code Studio
```bash
wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" -O vscode.tar.gz
tar -vzxf vscode.tar.gz -C /opt/ && rm vscode.tar.gz 
ln -sf /opt/VSCode-linux-x64/code /usr/bin/code
echo -e '[Desktop Entry]\nVersion=1.0\nName=vscode\nExec=code\nIcon=/opt/VSCode-linux-x64/resources/app/resources/linux/code.png\nType=Application\nCategories=Development;Application' | sudo tee /usr/share/applications/vscode.desktop
```

### Sublime Text
```bash
wget "https://download.sublimetext.com/sublime_text_3_build_3211_x64.tar.bz2" -O sublime_text.tar.bz2
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
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd ~ && rm -rf yay
```

### gnome-extension

```
yay -S --noconfirm --needed  chrome-gnome-shell gnome-shell-extension-dash-to-dock 
```

### Fonts
```bash
sudo pacman -S freetype2 terminus-font ttf-bitstream-vera ttf-dejavu ttf-droid ttf-fira-mono ttf-fira-sans ttf-freefont ttf-inconsolata ttf-liberation ttf-linux-libertine ttf-ubuntu-font-family xorg-xfontsel
```


## Installing Plasma and KDE:

```bash
pacman -S sddm plasma kde-applications plasma-nm sddm
```
### Plasma and KDE, livrar de elementos como jogos, o pacote KDE PIM (e-mail, contatos, etc) junto com o serviço akonadi, ferramentas multimídia, etc:

```bash
pacman -R kdemultimedia kdegames kdeedu discover telepathy-kde kopete umbrello kdepim-addons kdepim-apps-libs kdepim-runtime akonadi kaddressbook kalarm kmail kontact korganizer calendarsupport knotes messagelib akonadi-calendar-tools akonadiconsole akregator eventviews grantlee-editor mailcommon pim-data-exporter  akonadi-import-wizard incidenceeditor mbox-importer
```

### Enable the firewall

```bash
sudo pacman -S ufw
sudo ufw enable
sudo ufw status verbos
sudo systemctl enable ufw.service
```

### Install Media Codecs

```bash
sudo pacman -S exfat-utils fuse-exfat a52dec faac faad2 flac jasper lame libdca libdv gst-libav libmad libmpeg2 libtheora libvorbis libxv wavpack x264 xvidcore libdvdcss libdvdread libdvdnav dvd+rw-tools dvdauthor dvgrab
```


deepin-screenshot

### Install Inkscape Image Editor
```bash
sudo pacman -S inkscape
```

### Install Clementine Audio Player
```bash
sudo pacman -S clementine
```
<!-- 
nano /etc/sudoers

# %wheel ALL=(ALL) ALL -->


sudo pacman -Rns plasma plasma-wayland-session

git clone https://aur.archlinux.org/yay.git && cd yay
makepkg -si

<!-- 


    # git clone https://github.com/Match-Yang/sddm-deepin.git ~/sddm-deepin && mv -r ~/sddm-deepin/deepin ${MOINTPOINT}/usr/share/sddm/themes/
    # git clone https://github.com/totoro-ghost/sddm-astronaut.git ${MOINTPOINT}/usr/share/sddm/themes/astronaut/
    # sed -i "s/^Current=.*/Current=deepin/g" ${MOINTPOINT}/usr/lib/sddm/sddm.conf.d/default.conf

    # git clone https://github.com/jelenis/login-manager.git ${MOINTPOINT}/usr/share/lightdm-webkit/themes/lightdm-theme
    # sed -i "s/^greeter-session=.*/greeter-session=lightdm-webkit2-greeter/g" ${MOINTPOINT}/etc/lightdm/lightdm.conf
    # sed -i "s/^webkit_theme=.*/webkit_theme=lightdm-theme/g" ${MOINTPOINT}/etc/lightdm/lightdm-webkit2-greeter.conf

sudo rm /var/lib/pacman/db.lck
sudo rm /var/lib/pacman/sync/*
sudo rm -R /etc/pacman.d/gnupg
sudo pacman -Scc
sudo pacman -Sy gnupg archlinux-keyring
sudo pacman-key --init 
sudo pacman-key --populate archlinux
sudo pacman-key --refresh-keys 
sudo pacman -Syyu


/etc/profile.d/lang.sh

# en_US is the Slackware default locale:
export LANG=pt_BR
export LC_ALL=pt_BR
export LANGUAGE=pt_BR


Install_app() {
    cmd=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Menu " --output-fd 1 --separate-output --extra-button --extra-label 'Select All' --cancel-label 'Select None' --checklist 'Choose the tools to install:' 0 0 0 --stdout)
    app () {
        options=(
            'tilix' '' on
            'vlc' ''  off
            'libreoffice-fresh' '' off
            'lollypop' '' off
            'atom' '' off
            'gedit' '' off
            'mousepad' '' off
            'leafpad' '' on
            'chromium' '' off
            'midori' ''  off
            'firefox' '' on
            'brave' '' off
            'nodejs' '' off
            'npm' '' off
            'yarn' '' off
            'gimp' '' off
            'jre8-openjdk' '' on 
            'jre8-openjdk-headless' '' off
        )
        PKGS=$("${cmd[@]}" "${options[@]}")
    }
    app
    
    for PKG in "${PKGS[@]}"; do
        echo "INSTALLING: ${PKG}"
        arch_chroot "pacman -Sy "$PKG" --noconfirm --needed"
    done  
}




setxkbmap [-model xkb_model] [-layout xkb_layout] [-variant xkb_variant] [-option xkb_options]

setxkbmap -model abnt2 -layout br -variant ,abnt2

setxkbmap -model abnt2 -layout br -variant abnt2

setxkbmap br



setxkbmap -model pc104 -layout cz,us -variant ,dvorak -option grp:win_space_toggle



/etc/X11/xorg.conf.d/00-keyboard.conf

Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "cz,us"
        Option "XkbModel" "pc104"
        Option "XkbVariant" ",dvorak"
        Option "XkbOptions" "grp:win_space_toggle"
EndSection



setxkbmap -rules xorg -model pc104 -layout us -option ""

setxkbmap -rules xorg -model logicordless -layout "us,cz,de" -option "grp:alt_shift_toggle"


Section "InputDevice"
    Identifier "Keyboard1"
    Driver "kbd"

    Option "XkbModel" "logicordless"
    Option "XkbLayout" "us,cz,de"
    Option "XKbOptions" "grp:alt_shift_toggle"
EndSection



setxkbmap -rules xorg -model logicordless -layout "us,cz,de" -variant ",bksl," -option "grp:alt_shift_toggle"


Section "InputDevice"
    Identifier "Keyboard1"
    Driver "kbd"

    Option "XkbModel" "logicordless"
    Option "XkbLayout" "us,cz,de"
    Option "XkbVariant" ",bksl,"
    Option "XKbOptions" "grp:alt_shift_toggle"
EndSection


    
### powerlevel10k

```bash
yay -S --noconfirm --needed nerd-fonts-fira-code nordic-darker-standard-buttons-theme nordic-darker-theme nordic-theme

touch .cache/zshhistory
mv arch/zsh .zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
ln -s ~/.zsh/zshrc .zshrc

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc


chsh -s /usr/bin/zsh
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


git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

/etc/X11/xorg.conf.d/00-keyboard.conf



# Architecture
ARCHI=$(uname -m)
SYSTEM="Unknown"
VERSION="Arch Linux Pos-installer"


MOUNTPOINT=
ANSWER=".answer"

DIALOG() {
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --column-separator "|" --exit-label "$_Back" --title "$@"
}

set_xkbmap() {
    XKBMAP_LIST=""
    keymaps_xkb=("af al am at az ba bd be bg br bt bw by ca cd ch cm cn cz de dk ee es et eu fi fo fr\
      gb ge gh gn gr hr hu ie il in iq ir is it jp ke kg kh kr kz la lk lt lv ma md me mk ml mm mn mt mv\
      ng nl no np pc ph pk pl pt ro rs ru se si sk sn sy tg th tj tm tr tw tz ua us uz vn za")

    for i in ${keymaps_xkb}; do
        XKBMAP_LIST="${XKBMAP_LIST} ${i} -"
    done

    DIALOG " $_PrepKBLayout " --menu "\n$_XkbmapBody\n " 0 0 16 ${XKBMAP_LIST} 2>${ANSWER} || return 0
    XKBMAP=$(cat ${ANSWER} |sed 's/_.*//')
    
    echo -e "Section "\"InputClass"\"\nIdentifier "\"system-keyboard"\"\nMatchIsKeyboard "\"on"\"\nOption "\"XkbLayout"\" "\"${XKBMAP}"\"\nEndSection" \
      > ${MOUNTPOINT}/etc/X11/xorg.conf.d/00-keyboard.conf
}







set_xkbmap() {
    XKBMAP_LIST=""
    keymaps_xkb=("af al am at az ba bd be bg br bt bw by ca cd ch cm cn cz de dk ee es et eu fi fo fr\
      gb ge gh gn gr hr hu ie il in iq ir is it jp ke kg kh kr kz la lk lt lv ma md me mk ml mm mn mt mv\
      ng nl no np pc ph pk pl pt ro rs ru se si sk sn sy tg th tj tm tr tw tz ua us uz vn za")

    for i in ${keymaps_xkb}; do
        XKBMAP_LIST="${XKBMAP_LIST} ${i} -"
    done
    
    XKBMAP=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir a Localização do Sistema " --menu " t " 0 0 12  ${XKBMAP_LIST} --stdout)

    XKBMAP=$(echo ${ANSWER} | sed 's/_.*//')
    

    echo -e "Section "\"InputClass"\"\nIdentifier "\"system-keyboard"\"\nMatchIsKeyboard "\"on"\"\nOption "\"XkbLayout"\" "\"${XKBMAP}"\"\nEndSection" \
      > ${MOUNTPOINT}/etc/X11/xorg.conf.d/00-keyboard.conf
}









      "wayland" "-" off \
      "xorg-server" "-" on \
      "xorg-server-common" "-" off \
      "xorg-xinit" "-" on \
      "xorg-server-xwayland" "-" off \
      "xf86-input-evdev" "-" off \
      "xf86-input-keyboard" "-" on \
      "xf86-input-libinput" "-" on \
      "xf86-input-mouse" "-" on \
      "xf86-input-synaptics" "-" off 2>${PACKAGES}



      "awesome + vicious" "-" off \
      "budgie-desktop" "-" off \
      "cinnamon" "-" off \
      "deepin" "-" off \
      "deepin-extra" "-" off \
      "enlightenment + terminology" "-" off \
      "fluxbox + fbnews" "-" off \
      "gnome" "-" off \
      "gnome-extra" "-" off \
      "gnome-shell" "-" off \
      "i3-wm + i3lock + i3status" "-" off \
      "icewm + icewm-themes" "-" off \
      "jwm" "-" off \
      "kde-applications" "-" off \
      "lxde" "-" off \
      "lxqt + oxygen-icons" "-" off \
      "mate" "-" off \
      "mate-extra" "-" off \
      "mate-extra-gtk3" "-" off \
      "mate-gtk3" "-" off \
      "openbox + openbox-themes" "-" off \
      "pekwm + pekwm-themes" "-" off \
      "plasma" "-" off \
      "plasma-desktop" "-" off \
      "windowmaker" "-" off \
      "xfce4" "-" off \
      "xfce4-goodies" "-" off 2>${PACKAGES}


          "bash-completion" "-" on \
          "gamin" "-" on \
          "gksu" "-" on \
          "gnome-icon-theme" "-" on \
          "gnome-keyring" "-" on \
          "gvfs" "-" on \
          "gvfs-afc" "-" on \
          "gvfs-smb" "-" on \
          "polkit" "-" on \
          "poppler" "-" on \
          "python2-xdg" "-" on \
          "ntfs-3g" "-" on \
          "ttf-dejavu" "-" on \
          "xdg-user-dirs" "-" on \
          "xdg-utils" "-" on \
          "xterm" "-" on 2>${PACKAGES}


      "ufw" "-" off \
      "gufw" "-" off \
      "ntp" "-" off \
      "b43-fwcutter" "Broadcom 802.11b/g/n" off \
      "bluez-firmware" "Broadcom BCM203x / STLC2300 Bluetooth" off \
      "ipw2100-fw" "Intel PRO/Wireless 2100" off \
      "ipw2200-fw" "Intel PRO/Wireless 2200" off \
      "zd1211-firmware" "ZyDAS ZD1211(b) 802.11a/b/g USB WLAN" off 2>${PACKAGES}






      "cups" "-" on \
      "cups-pdf" "-" off \
      "ghostscript" "-" on \
      "gsfonts" "-" on \
      "samba" "-" off 2>${PACKAGES}


      ALSA=$(echo $ALSA | sed "s/alsa-utils - off/alsa-utils - on/g" | sed "s/alsa-plugins - off/alsa-plugins - on/g")

      $ALSA "pulseaudio" "-" off $PULSE_EXTRA \
      "paprefs" "pulseaudio GUI" off \
      "pavucontrol" "pulseaudio GUI" off \
      "ponymix" "pulseaudio CLI" off \
      "volumeicon" "ALSA GUI" off \
      "volwheel" "ASLA GUI" off 2>${PACKAGES}



      "accerciser" "-" off \
      "at-spi2-atk" "-" off \
      "at-spi2-core" "-" off \
      "brltty" "-" off \
      "caribou" "-" off \
      "dasher" "-" off \
      "espeak" "-" off \
      "espeakup" "-" off \
      "festival" "-" off \
      "java-access-bridge" "-" off \
      "java-atk-wrapper" "-" off \
      "julius" "-" off \
      "orca" "-" off \
      "qt-at-spi" "-" off \
      "speech-dispatcher" "-" off 2>${PACKAGES}








-->

### wine

```bash
sudo pacman -S --noconfirm wine wine-mono wine-gecko winetricks
```



<!-- lightdm lightdm-gtk-greeter lightdm-webkit2-greeter   

lightdm-webkit-theme-aether

systemctl enable lightdm.service


greeter-session=lightdm-webkit2-greeter   /etc/lightdm/lightdm.conf

$ git clone https://github.com/jelenis/login-manager.git
# cp -r lightdm-theme /usr/share/lightdm-webkit/themes/

webkit_theme=lightdm-theme  /etc/lightdm/lightdm-webkit2-greeter.conf
 -->

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
