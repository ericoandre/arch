#!/bin/bash

pacman -Syy && pacman -S --noconfirm dialog terminus-font reflector

######################################################################
##                                                                  ##
##                   Installer Variables                            ##
##                                                                  ##
######################################################################

# Architecture
ARCHI=$(uname -m)
SYSTEM="Unknown"
VERSION="Arch Linux Installer"

#
CURR_LOCALE=pt_BR.UTF-8
FONT=lat0-16
KEYMAP=br-abnt2
XKBMAP=br
ZONE=America
SUBZONE=Recife
CLOCK=utc
HNAME=ArchVM
KERNEL=linux

### 
dm_enabled=false
bluetooth_enabled=false
DESKTOP="None"
GUI=false
UEFI=false
DEpkg=()

### Installation
MOINTPOINT=/mnt
HD=/dev/sda

SWAP_SIZE=1024
BOOT_SIZE=512
ROOT_SIZE=0

BOOT_FS=ext2
ROOT_FS=ext4

BASE_PACKAGES=('base' 'base-devel' 'grub')
EXTRA_PKGS=('ntfs-3g' 'exfat-utils' 'os-prober' 'dosfstools' 'mtools' 'archlinux-keyring' 'glibc' 'ntp' 'sudo' 'go' 'ibus' 'dbus' 'dbus-glib' 'dbus-python' 'python' 'python-pip' 'scrot' 'screenfetch' 'wget' 'cmatrix' 'gcc' 'htop' 'make' 'git' 'pciutils' 'acpi' 'acpid' 'unrar' 'p7zip' 'tar' 'rsync' 'ufw' 'iptables' 'openbsd-netcat' 'traceroute' 'nmap' 'iw' 'net-tools' 'networkmanager' 'dhclient' 'dhcpcd' 'neofetch' 'nano' 'alsa-plugins' 'alsa-utils' 'alsa-firmware' 'pulseaudio' 'pulseaudio-alsa' 'pavucontrol' 'volumeicon' 'bash-completion' 'zsh' 'zsh-syntax-highlighting' 'zsh-autosuggestions')
FONTES_PKGS=('ttf-droid' 'noto-fonts' 'ttf-liberation' 'ttf-freefont' 'ttf-dejavu' 'ttf-hack' 'ttf-roboto' 'freetype2' 'terminus-font' 'ttf-bitstream-vera' 'ttf-dejavu' 'ttf-droid' 'ttf-fira-mono' 'ttf-fira-sans' 'ttf-freefont' 'ttf-inconsolata' 'ttf-liberation' 'ttf-linux-libertine' 'ttf-ubuntu-font-family' 'ttf-font-awesome' 'otf-font-awesome')

######## Variáveis auxiliares. NÃO DEVEM SER ALTERADAS
BOOT_START=1
BOOT_END=$(($BOOT_START+$BOOT_SIZE))

SWAP_START=$BOOT_END
SWAP_END=$(($SWAP_START+$SWAP_SIZE))

ROOT_START=$SWAP_END
ROOT_END=$(($ROOT_START+$ROOT_SIZE))

# Check for UEFI
if [ -d /sys/firmware/efi ]; then
  UEFI=true
fi

# Check for bluetooth support
if dmesg | grep -iq "blue"; then
  bluetooth=true
fi

######################################################################
##                                                                  ##
##                 Configuration Functions							##
##                                                                  ##
######################################################################

arch_chroot() {
    arch-chroot $MOINTPOINT /bin/bash -c "${1}"
}  
Parted() {
    parted --script $HD "${1}"
}
automatic_particao() {
    if $UEFI ; then
        # Configura o tipo da tabela de partições
        Parted "mklabel gpt"
        Parted "mkpart primary fat32 $BOOT_START $BOOT_END"
        Parted "set 1 esp on"
        mkfs.vfat -F32 -n BOOT ${HD}1
    else
        # Configura o tipo da tabela de partições
        Parted "mklabel msdos"
        Parted "mkpart primary $BOOT_FS $BOOT_START $BOOT_END"
        Parted "set 1 bios_grub on"
        mkfs.$BOOT_FS ${HD}1
    fi

    if $SWAPFILE ; then
      # Cria partição swap
      parted -s $HD mkpart primary linux-swap $SWAP_START $SWAP_END
      Parted "mkpart primary $ROOT_FS $ROOT_START -$ROOT_END"

      mkswap ${HD}2
      swapon ${HD}2

      # Formatando partição root
      mkfs.$ROOT_FS ${HD}3 -L Root
      mount ${HD}3 $MOINTPOINT
    else
      Parted "mkpart primary $ROOT_FS $BOOT_END -${ROOT_END}"

      # Formatando partição root
      mkfs.$ROOT_FS ${HD}2 -L Root
      mount ${HD}2 $MOINTPOINT

      mkdir -p  ${MOINTPOINT}/opt/swap && touch ${MOINTPOINT}/opt/swap/swapfile
      dd if=/dev/zero of=${MOINTPOINT}/opt/swap/swapfile bs=1M count=$SWAP_SIZE status=progress
      chmod 600 ${MOINTPOINT}/opt/swap/swapfile
      mkswap ${MOINTPOINT}/opt/swap/swapfile
      swapon ${MOINTPOINT}/opt/swap/swapfile
    fi
    
    if $UEFI ; then
        # Monta partição esp
        mkdir -p ${MOINTPOINT}/boot/efi && mount ${HD}1 ${MOINTPOINT}/boot/efi
    else
        # Monta partição boot
        mkdir -p ${MOINTPOINT}/boot && mount ${HD}1 ${MOINTPOINT}/boot
    fi
}

root_password() {
    rtpasswd=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Senha ROOT " --inputbox "\nDigite a senha Root \n\n" 10 50 --stdout)
    rtpasswd2=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Senha ROOT " --inputbox "\nDigite novamente a senha Root \n\n" 10 50 --stdout)
    
    if [ "$rtpasswd" != "$rtpasswd2" ]; then 
        dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Senha ROOT " --msgbox "As senhas não coincidem. Tente novamente." 10 50
        root_password
    else
        ROOT_PASSWD=$(echo $rtpasswd)
    fi
}
user_password() {
    userpasswd=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Adicionar Novo Usuário " --inputbox "\nDigite a senha para $USER" 10 50 --stdout)
    userpasswd2=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Adicionar Novo Usuário " --inputbox "\nDigite novamente a senha para $USER." 10 50 --stdout)
    if [[ "$userpasswd" != "$userpasswd2" ]]; then 
        dialog --title "$TITLE" --msgbox  "As senhas não coincidem. Tente novamente." 10 50
        user_password
    else
        USER_PASSWD=$(echo $userpasswd)
    fi
}

install_driver_virt() {
    #### auto-install VM drivers
    case $(systemd-detect-virt) in
      kvm)
          # xf86-video-qxl is disabled due to bugs on certain DEs
          arch_chroot "pacman -S spice-vdagent --noconfirm --needed"
      ;;
      vmware)
          arch_chroot "pacman -S open-vm-tools --noconfirm --needed"
          arch_chroot "systemctl enable vmtoolsd.service"
          arch_chroot "systemctl enable vmware-vmblock-fuse.service"
      ;;
      oracle)
          arch_chroot "pacman -S virtualbox-guest-utils xf86-video-vmware --noconfirm --needed"
          arch_chroot "systemctl enable vboxservice.service"
      ;;
    esac
    pacstrap /mnt xf86-input-synaptics synaptic
}

install_driver_videos() {
    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
        arch_chroot "pacman -S nvidia --noconfirm --needed"
        arch_chroot "nvidia-xconfig"
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        arch_chroot "pacman -S xf86-video-amdgpu --noconfirm --needed"
    elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
        arch_chroot "pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa --needed --noconfirm"
    elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
        arch_chroot "pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa --needed --noconfirm"
    fi
}
# ------------------------------------
config_install_root() {

    #### Install Bootloader
    if [ "$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')" = "GenuineIntel" ]; then
        EXTRA_PKGS+=('intel-ucode')
    elif [ "$proc" = "AuthenticAMD" ]; then
        EXTRA_PKGS+=('amd-ucode')
    fi

    [[ $UEFI ]] && EXTRA_PKGS+=('efibootmgr')
    DESKTOP=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Choose your Graphical Environment" --no-cancel --menu "Select the style of graphical environment you wish to \
    use.\n\nGraphical environment:" 12 75 3 \
    "Desktop Environment" "Traditional complete graphical user interface" \
    "Window Manager" "Standalone minimal graphical user interface" \
    "None" "Command-line only interface" --stdout)

    if [ "$DESKTOP" != "None" ]; then
        DEpkg+=('xorg' 'xorg-xkbcomp' 'xorg-xinit' 'xorg-server' 'xorg-twm' 'xorg-xclock' 'xorg-drivers' 'xorg-xkill' 'xorg-fonts-100dpi' 'xorg-fonts-75dpi' 'mesa' 'xterm' 'audacious' 'pulseaudio' 'pulseaudio-alsa' 'pavucontrol' 'xscreensaver' 'archlinux-wallpaper' 'xdg-user-dirs-gtk' 'adwaita-icon-theme' 'papirus-icon-theme' 'oxygen-icons' 'faenza-icon-theme')
        if [ "$DESKTOP" = "Desktop Environment" ]; then
            GUI=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Select a Desktop Environment" --menu "Select a desktop environment to install:" 15 65 8 \
            "GNOME" "Modern MiNIMAL simplicity focused desktop" \
            "KDE Plasma" "Full featured QT based desktop" \
            "Deepin" "Deepin desktop with extra software" \
            "Cinnamon" "Traditional desktop experience" \
            "LXDE" "Lightweight and efficient desktop" \
            "LXQT" "Lightweight and efficient QT based desktop" \
            "Xfce" "Lightweight and modular desktop"  --stdout)
        elif [ "$DESKTOP" = "Window Manager" ]; then    
            GUI=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Select a Window Manager" --menu "Select a window manager to install:" 13 75 6 \
            "awesome" "Highly configurable, dynamic window manager" \
            "i3" "Dynamic tiling window manager inspired by wmii" \
            "Openbox" "Highly configurable, stacking window manager" \
            "xmonad" "Dynamic tiling window manager configured in Haskell" --stdout)
        fi
        case $GUI in
            "GNOME") DEpkg+=('gnome-shell' 'gnome-backgrounds' 'gnome-control-center' 'gnome-screenshot' gnome-system-monitor gnome-terminal gnome-tweak-tool nautilus gvfs gnome-calculator gnome-disk-utility) ;;
            "KDE Plasma") DEpkg+=('plasma' 'dolphin' 'plasma-wayland-session' 'konsole' 'kate' 'kcalc' 'ark' 'gwenview' 'spectacle' 'okular' 'packagekit-qt5') ;;
            "Cinnamon") DEpkg+=('cinnamon' 'sakura' 'gnome-disk-utility' 'nemo-fileroller' 'gnome-software' 'gnome-system-monitor' 'gnome-screenshot') ;;
            "Xfce") DEpkg=('xfce4' 'xfce4-goodies' 'file-roller') ;;
            "Deepin") DEpkg+=('plocate' 'lm_sensors' 'gvfs' 'gvfs-mtp' 'sysstat' 'deepin-picker' 'ntp' 'exfat-utils' 'deepin-community-wallpapers' 'qalculate-gtk' 'kodi-x11' 'deepin-control-center' 'deepin-kwin'  'deepin-shortcut-viewer' 'deepin-system-monitor' 'deepin-turbo' 'fractal' 'deepin-terminal-gtk' 'deepin-reader' 'deepin-editor' 'firefox' 'thunderbird' 'telegram-desktop' 'deepin-music' 'deepin-screenshot' 'deepin-compressor' 'deepin-printer' 'qbittorrent' 'deepin-image-viewer' 'deepin-album' 'kodi' 'simplescreenrecorder' 'guvcview-qt' 'aria2' 'pdfarranger' 'bpytop' 'git' 'wget' 'neofetch' 'nano' 'reflector' 'p7zip' 'unarchiver' 'sharutils' 'youtube-dl' 'mesa-demos' 'tree' 'bind-tools' 'dmidecode' 'hddtemp' 'jshon' 'expac' 'cups' 'cups-pdf' 'xorg-xinit' 'inetutils' 'keepassxc' 'flatpak' 'speedtest-cli' 'wavemon' 'cronie' 'uget' 'python-sip' 'usbutils' 'bash-completion' 'pacman-contrib' 'unarj' 'cpio' ) ;; # =('deepin' 'deepin-extra' 'ark' 'gnome-disk-utility') ;;
            "LXDE") DEpkg+=('lxde') ;;
            "LXQT") DEpkg=('lxqt' 'xdg-utils' 'libpulse' 'libstatgrab' 'libsysstat' 'lm_sensors' 'pavucontrol-qt') ;;
            "awesome") DEpkg+=('awesome') ;;
            "i3") DEpkg+=('i3') ;;
            "Openbox") DEpkg+=('openbox') ;;
            "xmonad") DEpkg+=('xmonad' 'xmonad-contrib') ;;
        esac

        if [ "$GUI" != "GNOME" ]; then
            if [ "$GUI" = "KDE Plasma" ]; then
                DEpkg+=('plasma-nm')
            else
                DEpkg+=('network-manager-applet' 'gnome-keyring')
            fi
        fi
        DM=$(dialog  --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)"  --title "Install a Display Manager" --menu "Select a display manager to install:" 10 50 3 "gdm" "GNOME Display Manager" "lightdm" "Lightweight Display Manager" "sddm" "Simple Desktop Display Manager" --stdout)
        if [ $? -eq 0 ]; then
            dm_enabled=true
            case "$DM" in
                "gdm") DEpkg+=('gdm') ;;
                "lxdm ") DEpkg+=('lxdm') ;;
                "lightdm") DEpkg+=('lightdm' 'lightdm-gtk-greeter' 'lightdm-gtk-greeter-settings') ;;
                "sddm") DEpkg+=('sddm') ;;
            esac
        else
            case "$GUI" in
                "Cinnamon") xinit_config="exec cinnamon-session" ;;
                "Deepin")   xinit_config="exec startdde" ;;
                "GNOME") xinit_config="exec gnome-session" ;;
                "KDE Plasma") xinit_config="exec startkde" ;;
                "LXDE") xinit_config="exec startlxde" ;;
                "LXQT") xinit_config="exec startlxqt" ;;
                "Xfce") xinit_config="exec startxfce4" ;;
                "awesome") xinit_config="exec awesome" ;;
                "bspwm") xinit_config="sxhkd & ; exec bspwm" ;;
                "Fluxbox") xinit_config="exec startfluxbox" ;;
                "i3") xinit_config="exec i3" ;;
                "Openbox") xinit_config="exec openbox-session" ;;
                "xmonad") xinit_config="exec xmonad" ;;
            esac
        fi

        if $bluetooth; then
            bluetooth_enabled=true
            DEpkg+=('bluez' 'bluez-utils' 'pulseaudio-bluetooth')
            dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Install Bluetooth Manager" --yesno "Would you like to install a graphical Bluetooth manager?\n\nThe utility that best integrates with the desktop environment you selected will be installed." 8 60
            if [ $? -eq 0 ]; then
                case "$GUI" in
                    "GNOME") DEpkg+=('gnome-bluetooth') ;;
                    "Cinnamon") DEpkg+=('blueberry') ;;
                    "KDE Plasma") DEpkg+=('bluedevil') ;;
                    *) DEpkg+=('blueman') ;;
                esac
            fi
        fi
    fi
}
install_root() {
    pacstrap $MOINTPOINT "${BASE_PACKAGES[@]}" ${KERNEL} ${KERNEL}-headers ${KERNEL}-firmware "${EXTRA_PKGS[@]}" "${FONTES_PKGS[@]}" "${DEpkg[@]}"
}
config_base() {
    cp /etc/pacman.d/mirrorlist ${MOINTPOINT}/etc/pacman.d/mirrorlist
    #[[ "$(uname -m)" = "x86_64" ]] && sed -i '/multilib\]/,+1 s/^#//' ${MOINTPOINT}/etc/pacman.conf
    #arch_chroot "pacman -Sy && pacman-key --init && pacman-key --populate archlinux"

    #### setting hostname
    echo ${HNAME} > ${MOINTPOINT}/etc/hostname
    echo -e "127.0.0.1    localhost.localdomain    localhost\n::1        localhost.localdomain    localhost\n127.0.1.1    $HNAME.localdomain    $HNAME" >> ${MOINTPOINT}/etc/hosts

    #### locales setting locale pt_BR.UTF-8 UTF-8
    echo -e "LANG=${LOCALE}\nLC_MESSAGES=${LOCALE}" > ${MOINTPOINT}/etc/locale.conf
    sed -i "s/#${LOCALE}/${LOCALE}/" ${MOINTPOINT}/etc/locale.gen
    arch_chroot "locale-gen"
    arch_chroot "export LANG=${LOCALE}"

    #### virtual console keymap
    echo -e "KEYMAP=${KEYMAP}\nFONT=${FONT}" > ${MOINTPOINT}/etc/vconsole.conf

    #### Setting timezone
    arch_chroot "ln -s /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime"

    #### Setting hw CLOCK
    arch_chroot "hwclock --systohc --${CLOCK}"

    #### root password
    arch_chroot "echo -e $ROOT_PASSWD'\n'$ROOT_PASSWD | passwd"

    #### criar usuario Definir senha do usuário 
    arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash ${USER}"
    arch_chroot "echo -e $USER_PASSWD'\n'$USER_PASSWD | passwd `echo $USER`"

    # ativando DM
    if [[ $dm_enabled ]] ; then
        arch_chroot "systemctl enable ${DM}.service"
    else
        echo "$xinit_config" > ${MOINTPOINT}/home/"$USER"/.xinitrc
    fi

    #### fstab
    genfstab -U -p $MOINTPOINT >> ${MOINTPOINT}/etc/fstab

    #### networkmanager acpi
    arch_chroot "systemctl enable NetworkManager.service acpid.service ntpd.service"
    
    install_driver_virt
    [[ "$DESKTOP" != "None" ]] && install_driver_videos

    # Configura ambiente ramdisk inicial
    arch_chroot "mkinitcpio -p ${KERNEL}"
}
install_bootloader() {
    if $UEFI ; then
        arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck"
        mkdir ${MOINTPOINT}/boot/efi/EFI/boot && mkdir ${MOINTPOINT}/boot/grub/locale
        cp ${MOINTPOINT}/boot/efi/EFI/grub_uefi/grubx64.efi ${MOINTPOINT}/boot/efi/EFI/boot/bootx64.efi
    else
        arch_chroot "grub-install --target=i386-pc --recheck $HD"
    fi
    cp ${MOINTPOINT}/usr/share/locale/en@quot/LC_MESSAGES/grub.mo ${MOINTPOINT}/boot/grub/locale/en.mo
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}
reboote(){
    dialog --clear --title " Installation finished sucessfully " --yesno "\nDo you want to reboot?" 7 62
    if [[ $? -eq 0 ]]; then
        echo "System will reboot in a moment..."
        sleep 3
        # clear
        umount -R $MOINTPOINT
        reboot
    fi
}

######################################################################
##                                                                  ##
##                            Execution                             ##
##                                                                  ##
######################################################################

reflector --verbose --protocol http --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
[[ "$(uname -m)" = "x86_64" ]] && sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf && pacman -Sy
pacman -Sy && pacman-key --init && pacman-key --populate archlinux

timedatectl set-ntp true
[[ $FONT != "" ]] && setfont $FONT
loadkeys $KEYMAP  # br-abnt2

### 
KERNEL=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)"  --title "$TITLE" --radiolist "Existem vários kernels disponíveis para o sistema.\n\nO mais comum é o atual kernel linux.\nEste kernel é o mais atualizado, oferecendo o melhor suporte de hardware.\nNo entanto, pode haver possíveis erros nesse kernel, apesar dos testes.\n\nO kernel linux-lts fornece um foco na estabilidade.\nEle é baseado em um kernel mais antigo, por isso pode não ter alguns recursos mais recentes.\n\nO kernel com proteção do linux é focado na segurança \nEle contém o Grsecurity Patchset e o PaX para aumentar a segurança. \n\nO kernel do linux-zen é o resultado de uma colaboração de hackers do kernel \npara fornecer o melhor kernel possível para os sistemas cotidianos. \n\nPor favor, selecione o kernel que você deseja instalar." 50 100 100 linux "" on linux-lts "" off linux-hardened "" off linux-zen "" off --stdout)

#### configure base system
LOCALE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir a Localização do Sistema " --menu "A localização (locale) determina o idioma a ser exibido, os formatos de data e hora, etc...\n\nO formato é idioma_PAÍS (ex.: en_US é inglês, Estados Unidos; pt_PT é português, Portugal)." 0 0 12 $(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 | sort | awk '{ printf $0 " - " }') --stdout)

### Set the installed system's hostname
HNAME=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Nome da Máquina " --inputbox "\nO hostname é usado para identificar o sistema em uma rede.\n\nE é restrito aos caracteres alfa numéricos, pode conter um hifen (-) - mas não no inicio ou no fim - e não deve ser maior que 63 caracteres.\n" 15 60 --stdout)

### Set Zone and Sub-Zone
ZONE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --menu "\nO fuso horário é usado para definir correctamente o relógio do sistema." 20 50 50 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud | sort | awk '{ printf ""$0""  " - " }') --stdout)
SUBZONE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --menu "\nSeleccione a cidade mais próxima de você." 20 50 50 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "$ZONE/" | sed "s/$ZONE\///g" | sort -ud | sort | awk '{ printf ""$0""  " - " }') --stdout)

###
CLOCK=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --radiolist "\nUTC é o padrão de tempo universal e é recomendado a menos que tenha dual-boot com o Windows." 12 50 30 "utc" "" ON "localtime" "" OFF --stdout)

###
dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Criar Swap " --clear --yesno "\nCriar memoria de paginação Swap em arquivo?" 7 50
[[ $? -eq 1 ]] && SWAPFILE=true

# Definir Senha Root
root_password

# Criar Novo Usuário
USER=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Criar Novo Usuário " --inputbox "\nDigite o nome do usuário. As letras DEVEM ser minúsculas.\n" 10 50 --stdout)
user_password

#### Particionamento esta configurado para usar todo o hd
automatic_particao

#### Instalcao
config_install_root
install_root
config_base
install_bootloader

# #### yay e powerlevel10k
# git clone https://aur.archlinux.org/yay.git ${MOINTPOINT}/home/${USER}
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${MOINTPOINT}/home/${USER}/.powerlevel10k
# # arch_chroot "chsh -s /usr/bin/zsh"

# #### configure base system
# dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "INTEFACE GRAFICA" --clear --yesno "\nDeseja Instalar Windows Manager ?" 7 50
# if [[ $? -eq 0 ]]; then
#     install_descktopmanager
# fi

# reboote
