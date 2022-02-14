#!/bin/bash

######################################################################
##                   Installer Variables                            ##
######################################################################

# Architecture
ARCHI=$(uname -m)
SYSTEM="Unknown"
VERSION="Arch Linux Installer"

# 
UEFI=false

BASE_PACKAGES=('base' 'base-devel' 'grub' 'archlinux-keyring' 'networkmanager' 'dhclient' 'dhcpcd' 'sudo' 'net-tools' 'nano')
BASE_EXTRAS=('ntp' 'ntfs-3g' 'exfat-utils' 'bash-completion' 'neofetch' 'screenfetch' 'scrot' 'ufw' 'iptables' 'git' 'dosfstools' 'os-prober' 'mtools' 'xf86-input-libinput' 'xf86-input-synaptics' 'net-tools' 'acpi' 'acpid' 'dbus' 'pciutils' 'gvfs' 'alsa-plugins' 'alsa-utils' 'alsa-firmware' 'volumeicon' 'pavucontrol' 'pulseaudio' 'pulseaudio-alsa' 'xdg-user-dirs' 'zsh' 'zsh-syntax-highlighting' 'zsh-autosuggestions' 'ttf-droid' 'noto-fonts' 'ttf-liberation' 'ttf-freefont' 'ttf-dejavu' 'ttf-hack' 'ttf-roboto' 'freetype2' 'terminus-font' 'ttf-bitstream-vera' 'ttf-dejavu' 'ttf-droid' 'ttf-fira-mono' 'ttf-fira-sans' 'ttf-freefont' 'ttf-inconsolata' 'ttf-liberation' 'ttf-linux-libertine' 'ttf-ubuntu-font-family')

DESKTOP_DEFAULTS=('xscreensaver' 'cmatrix' 'archlinux-wallpaper' 'xdg-user-dirs-gtk' 'audacious' 'xorg' 'xorg-xkbcomp' 'xorg-xinit' 'xorg-server' 'xorg-twm' 'xorg-xclock' 'xorg-drivers' 'xorg-xkill' 'xorg-fonts-100dpi' 'xorg-fonts-75dpi' 'xorg-xfontsel' 'mesa' 'xterm' )

#  go ibus dbus-glib dbus-python python python-pip wget htop gcc glibc make unrar p7zip tar rsync 
# openbsd-netcat traceroute nmap iw 
# 'adwaita-icon-theme' 'papirus-icon-theme' 'oxygen-icons' 'faenza-icon-theme' 'breeze-icons'

# Config Suport
KERNEL=linux
CURR_LOCALE=pt_BR.UTF-8
FONT=lat0-16
KEYMAP=br-abnt2
XKBMAP=""
ZONE=America
SUBZONE=Recife
CLOCK=utc
HNAME=ArchVM

DESKTOP=false
GUI=false

# Installation
MOINTPOINT=/mnt
DISK=/dev/sda

SWAP_SIZE=1024
BOOT_SIZE=512

BOOT_FS=ext2
ROOT_FS=ext4

######## Variáveis auxiliares. NÃO DEVEM SER ALTERADAS
BOOT_START=1
BOOT_END=$(($BOOT_START+$BOOT_SIZE))

SWAP_START=$BOOT_END
SWAP_END=$(($SWAP_START+$SWAP_SIZE))

ROOT_START=$SWAP_END
ROOT_END=-0

# Check for UEFI
if [ -d /sys/firmware/efi ]; then
  UEFI=true
fi

# Check for bluetooth support
if dmesg | grep -iq "blue"; then
  bluetooth=true
fi

######################################################################
##                   Installer Variables                            ##
######################################################################

arch_chroot() {
    arch-chroot ${MOINTPOINT} /bin/bash -c "${1}"
}

Parted() {
    parted --script ${DISK} "${1}"
}

automatic_particao() {
    if $UEFI ; then
        # Configura o tipo da tabela de partições
        Parted "mklabel gpt"
        Parted "mkpart primary fat32 $BOOT_START $BOOT_END"
        Parted "set 1 esp on"
        mkfs.vfat -F32 -n BOOT ${DISK}1
    else
        # Configura o tipo da tabela de partições
        Parted "mklabel msdos"
        Parted "mkpart primary $BOOT_FS $BOOT_START $BOOT_END"
        Parted "set 1 bios_grub on"
        mkfs.$BOOT_FS ${DISK}1
    fi
  
   if $SWAPFILE ; then
      Parted "mkpart primary $ROOT_FS $BOOT_END ${ROOT_END}"

      # Formatando partição root
      mkfs.$ROOT_FS ${DISK}2 -L Root
      mount ${DISK}2 $MOINTPOINT

      mkdir -p  ${MOINTPOINT}/opt/swap && touch ${MOINTPOINT}/opt/swap/swapfile
      dd if=/dev/zero of=${MOINTPOINT}/opt/swap/swapfile bs=1M count=$SWAP_SIZE status=progress
      chmod 600 ${MOINTPOINT}/opt/swap/swapfile
      mkswap ${MOINTPOINT}/opt/swap/swapfile
      swapon ${MOINTPOINT}/opt/swap/swapfile
   else 
      
      # Cria partição swap
      parted -s $DISK mkpart primary linux-swap $SWAP_START $SWAP_END
      Parted "mkpart primary $ROOT_FS $ROOT_START ${ROOT_END}"

      mkswap ${DISK}2
      swapon ${DISK}2

      # Formatando partição root
      mkfs.${ROOT_FS} ${DISK}3 -L Root
      mount ${DISK}3 ${MOINTPOINT}
    fi
    
    
    if $UEFI ; then
        # Monta partição esp
        mkdir -p ${MOINTPOINT}/boot/efi && mount ${DISK}1 ${MOINTPOINT}/boot/efi
    else
        # Monta partição boot
        mkdir -p ${MOINTPOINT}/boot && mount ${DISK}1 ${MOINTPOINT}/boot
    fi
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
}

config_install() {
    bluetooth_enabled=false
    dm_enabled=false

    DESKTOP_PACKAGES=()
    DESKTOP_PACKAGES+=("${DESKTOP_DEFAULTS[@]}")
    
    [[ $UEFI ]] && DESKTOP_PACKAGES+=('efibootmgr')
    
    if [ "$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')" = "GenuineIntel" ]; then
        DESKTOP_PACKAGES+=('intel-ucode')
    elif [ "$proc" = "AuthenticAMD" ]; then
        DESKTOP_PACKAGES+=('amd-ucode')
    fi
    
    DESKTOP=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Choose your Graphical Environment" --no-cancel --menu "Select the style of graphical environment you wish to \
    use.\n\nGraphical environment:" 12 75 3 \
    "Desktop Environment" "Traditional complete graphical user interface" \
    "Window Manager" "Standalone minimal graphical user interface" \
    "None" "Command-line only interface"  --stdout)
    
    if [ "$DESKTOP" = "Desktop Environment" ]; then
        GUI=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Select a Desktop Environment" --menu "Select a desktop environment to install:" 15 65 8 \
        "Budgie" "Modern GNOME based desktop" \
        "Cinnamon" "Traditional desktop experience" \
        "Deepin" "Deepin desktop with extra software" \
        "GNOME" "Modern simplicity focused desktop" \
        "GNOME-SHELL" "Modern MiNIMAL simplicity focused desktop" \
        "KDE Plasma" "Full featured QT based desktop" \
        "LXDE" "Lightweight and efficient desktop" \
        "LXQT" "Lightweight and efficient QT based desktop" \
        "MATE" "Continuation of the GNOME 2 desktop" \
        "Xfce" "Lightweight and modular desktop"  --stdout)
    elif [ "$DESKTOP" = "Window Manager" ]; then    
        GUI=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Select a Window Manager" --menu "Select a window manager to install:" 13 75 6 \
        "awesome" "Highly configurable, dynamic window manager" \
        "bspwm" "Tiling window manager based on binary space partitioning" \
        "Fluxbox" "Stacking window manager based on Blackbox" \
        "i3" "Dynamic tiling window manager inspired by wmii" \
        "Openbox" "Highly configurable, stacking window manager" \
        "xmonad" "Dynamic tiling window manager configured in Haskell" --stdout)
    fi

    
    if [ "$DESKTOP" != "None" ]; then
        case "$GUI" in
            "Budgie") DESKTOP_PACKAGES+=('budgie-desktop' 'gnome-control-center' 'mutter') ;;
            "Cinnamon") DESKTOP_PACKAGES+=('cinnamon' 'cinnamon-translations' 'nemo-fileroller') ;;
            "Deepin") DESKTOP_PACKAGES+=( 'plocate' 'lm_sensors' 'gvfs' 'gvfs-mtp' 'sysstat' 'deepin-picker' 'ntp' 'exfat-utils' 'ntfs-3g' 'deepin-community-wallpapers' 'qalculate-gtk' 'kodi-x11' 'deepin-control-center' 'deepin-kwin'  'deepin-shortcut-viewer' 'deepin-system-monitor' 'deepin-turbo' 'fractal' 'deepin-terminal-gtk' 'deepin-reader' 'deepin-editor' 'firefox' 'thunderbird' 'telegram-desktop' 'deepin-music' 'deepin-screenshot' 'deepin-compressor' 'deepin-printer' 'qbittorrent' 'deepin-image-viewer' 'deepin-album' 'kodi' 'simplescreenrecorder' 'guvcview-qt' 'aria2' 'pdfarranger' 'bpytop' 'git' 'wget' 'neofetch' 'nano' 'reflector' 'p7zip' 'unarchiver' 'sharutils' 'youtube-dl' 'mesa-demos' 'tree' 'bind-tools' 'dmidecode' 'hddtemp' 'jshon' 'expac' 'cups' 'cups-pdf' 'xorg-xinit' 'inetutils' 'keepassxc' 'flatpak' 'speedtest-cli' 'wavemon' 'cronie' 'uget' 'python-sip' 'usbutils' 'bash-completion' 'pacman-contrib' 'unarj' 'cpio' ) ;;
            "GNOME") DESKTOP_PACKAGES+=('gnome' 'gnome-extra' 'gnome-tweak-tool') ;;
            "GNOME-SHELL") DESKTOP_PACKAGES+=('gnome-shell' 'gnome-backgrounds' 'gnome-control-center' 'gnome-screenshot' 'gnome-system-monitor' 'gnome-terminal' 'gnome-tweak-tool' 'nautilus' 'gvfs' 'gnome-calculator' 'gnome-disk-utility') ;;
            "KDE Plasma") DESKTOP_PACKAGES+=('plasma' 'dolphin' 'plasma-wayland-session' 'konsole' 'kate' 'kcalc' 'ark' 'gwenview' 'spectacle' 'okular' 'packagekit-qt5') ;;
            "LXDE") DESKTOP_PACKAGES+=('lxde') ;;
            "LXQT") DESKTOP_PACKAGES+=('lxqt' xdg-utils libpulse libstatgrab libsysstat lm_sensors 'pavucontrol-qt') ;;
            "MATE") DESKTOP_PACKAGES+=('mate' 'mate-extra' 'gtk-engines' 'gtk-engine-murrine') ;;
            "Xfce") DESKTOP_PACKAGES+=('xfce4' 'xfce4-goodies') ;;
            "awesome") DESKTOP_PACKAGES+=('awesome') ;;
            "bspwm") DESKTOP_PACKAGES+=('bspwm' 'sxhkd') ;; # xinit_config="sxhkd & ; exec bspwm"
            "Fluxbox") DESKTOP_PACKAGES+=('fluxbox') ;;
            "i3") DESKTOP_PACKAGES+=('i3') ;;
            "Openbox") DESKTOP_PACKAGES+=('openbox') ;;
            "xmonad") DESKTOP_PACKAGES+=('xmonad' 'xmonad-contrib') ;;
        esac

        if [ "$GUI" != "GNOME" ]; then
            if [ "$GUI" = "KDE Plasma" ]; then
                DESKTOP_PACKAGES+=('plasma-nm')
            else
                DESKTOP_PACKAGES+=('network-manager-applet' 'gnome-keyring')
            fi
        fi
        
        if $bluetooth; then
            bluetooth_enabled=true
            DESKTOP_PACKAGES+=('bluez' 'bluez-utils' 'pulseaudio-bluetooth')
            dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Install Bluetooth Manager" --yesno "Would you like to install a graphical Bluetooth manager?\n\nThe utility that best integrates with the desktop environment you selected will be installed." 8 60
            if [ $? -eq 0 ]; then
                case "$GUI" in
                    "Budgie"|"GNOME") DESKTOP_PACKAGES+=('gnome-bluetooth') ;;
                    "Cinnamon") DESKTOP_PACKAGES+=('blueberry') ;;
                    "KDE Plasma") DESKTOP_PACKAGES+=('bluedevil') ;;
                    *) DESKTOP_PACKAGES+=('blueman') ;;
                esac
            fi
        fi
        
        DM=$(dialog  --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)"  --title "Install a Display Manager" --menu "Select a display manager to install:" 10 50 3 "gdm" "GNOME Display Manager" "lightdm" "Lightweight Display Manager" "sddm" "Simple Desktop Display Manager" --stdout)
        if [ $? -eq 0 ]; then
            dm_enabled=true
            case "$DM" in
                "gdm") DESKTOP_PACKAGES+=('gdm') ;;
                "lxdm ") DESKTOP_PACKAGES+=('lxdm') ;;
                "lightdm") DESKTOP_PACKAGES+=('lightdm' 'lightdm-gtk-greeter' 'lightdm-gtk-greeter-settings') ;;
                "sddm") DESKTOP_PACKAGES+=('sddm') ;;
            esac 
        fi
    fi
}
install_base() {
    pacstrap $MOINTPOINT "${BASE_PACKAGES[@]}" ${KERNEL} ${KERNEL}-headers ${KERNEL}-firmware grub "${BASE_EXTRAS[@]}" "${DESKTOP_PACKAGES[@]}"
    Install_app
}
config_base() {
    #### fstab
    genfstab -U -p $MOINTPOINT >> ${MOINTPOINT}/etc/fstab
    
    #### Setting timezone
    arch_chroot "ln -s /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime"
    
    #### Setting hw CLOCK
    arch_chroot "hwclock --systohc --${CLOCK}"
    
    #### locales setting locale pt_BR.UTF-8 UTF-8
    sed -i "s/#${LOCALE}/${LOCALE}/" ${MOINTPOINT}/etc/locale.gen
    arch_chroot "locale-gen"
    echo -e "LANG=${LOCALE}\nLC_MESSAGES=${LOCALE}" > ${MOINTPOINT}/etc/locale.conf
    arch_chroot "export LANG=${LOCALE}"
    
    #### virtual console keymap
    echo -e "KEYMAP=${KEYMAP}\nFONT=${FONT}" > ${MOINTPOINT}/etc/vconsole.conf
    
    #### setting hostname
    echo ${HNAME} > ${MOINTPOINT}/etc/hostname
    echo -e "127.0.0.1    localhost.localdomain    localhost\n::1        localhost.localdomain    localhost\n127.0.1.1    $HNAME.localdomain    $HNAME" >> ${MOINTPOINT}/etc/hosts
    
    #### root password
    arch_chroot "echo -e $ROOT_PASSWD'\n'$ROOT_PASSWD | passwd"
    
    #### criar usuario Definir senha do usuário 
    arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash ${USER}"
    arch_chroot "echo -e $USER_PASSWD'\n'$USER_PASSWD | passwd `echo $USER`"

    arch_chroot "pacman -U https://github.com/ericoandre/arch/raw/main/yay-11.1.0.tar.gz"
    
    [[ "$(uname -m)" = "x86_64" ]] && sed -i '/multilib\]/,+1 s/^#//' ${MOINTPOINT}/etc/pacman.conf
    cp /etc/pacman.d/mirrorlist ${MOINTPOINT}/etc/pacman.d/mirrorlist
    arch_chroot "pacman -Sy && pacman-key --init && pacman-key --populate archlinux"
    arch_chroot "systemctl enable NetworkManager.service acpid.service ntpd.service"
    [[ $bluetooth_enabled ]] && arch_chroot "systemctl enable bluetooth.service"
    [[ $dm_enabled ]] && arch_chroot "systemctl enable ${DM}.service"

    arch_chroot "mkinitcpio -p ${KERNEL}"
    
    install_driver_videos
    install_driver_virt
}
install_boot() {
    if $UEFI ; then
        arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck"
        mkdir ${MOINTPOINT}/boot/efi/EFI/boot && mkdir ${MOINTPOINT}/boot/grub/locale
        cp ${MOINTPOINT}/boot/efi/EFI/grub_uefi/grubx64.efi ${MOINTPOINT}/boot/efi/EFI/boot/bootx64.efi
    else
        arch_chroot "grub-install --target=i386-pc --recheck $DISK"
        grub-install --target=i386-pc --recheck /dev/sda
    fi
    cp ${MOINTPOINT}/usr/share/locale/en@quot/LC_MESSAGES/grub.mo ${MOINTPOINT}/boot/grub/locale/en.mo
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
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

Install_app() {
    cmd=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Menu " --output-fd 1 --separate-output --extra-button --extra-label 'Select All' --cancel-label 'Select None' --checklist 'Choose the tools to install:' 0 0 0 --stdout)
    app () {
        options=(
            'deepin-screenshot' ''  off
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

######################################################################
##                            Execution                             ##
######################################################################

timedatectl set-ntp true
pacman -Syy && pacman -S --noconfirm dialog terminus-font reflector 
[[ "$(uname -m)" = "x86_64" ]] && sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf
reflector --verbose --protocol http --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist && pacman -Syy

dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Criar Swap " --clear --yesno "\nCriar memoria de paginação Swap em arquivo?" 7 50
if [[ $? -eq 1 ]]; then
  SWAPFILE=true
fi

KERNEL=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)"  --title "$TITLE" --radiolist "Existem vários kernels disponíveis para o sistema.\n\nO mais comum é o atual kernel linux.\nEste kernel é o mais atualizado, oferecendo o melhor suporte de hardware.\nNo entanto, pode haver possíveis erros nesse kernel, apesar dos testes.\n\nO kernel linux-lts fornece um foco na estabilidade.\nEle é baseado em um kernel mais antigo, por isso pode não ter alguns recursos mais recentes.\n\nO kernel com proteção do linux é focado na segurança \nEle contém o Grsecurity Patchset e o PaX para aumentar a segurança. \n\nO kernel do linux-zen é o resultado de uma colaboração de hackers do kernel \npara fornecer o melhor kernel possível para os sistemas cotidianos. \n\nPor favor, selecione o kernel que você deseja instalar." 50 100 100 linux "" on linux-lts "" off linux-hardened "" off linux-zen "" off --stdout)

#### configure base system
LOCALE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir a Localização do Sistema " --menu "A localização (locale) determina o idioma a ser exibido, os formatos de data e hora, etc...\n\nO formato é idioma_PAÍS (ex.: en_US é inglês, Estados Unidos; pt_PT é português, Portugal)." 0 0 12 $(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 | sort | awk '{ printf $0 " - " }') --stdout)

# Set the installed system's hostname
HNAME=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Nome da Máquina " --inputbox "\nO hostname é usado para identificar o sistema em uma rede.\n\nE é restrito aos caracteres alfa numéricos, pode conter um hifen (-) - mas não no inicio ou no fim - e não deve ser maior que 63 caracteres.\n" 15 60 --stdout)

# Set Zone and Sub-Zone
ZONE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --menu "\nO fuso horário é usado para definir correctamente o relógio do sistema." 20 50 50 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud | sort | awk '{ printf ""$0""  " - " }') --stdout)
SUBZONE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --menu "\nSeleccione a cidade mais próxima de você." 20 50 50 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "$ZONE/" | sed "s/$ZONE\///g" | sort -ud | sort | awk '{ printf ""$0""  " - " }') --stdout)

CLOCK=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --radiolist "\nUTC é o padrão de tempo universal e é recomendado a menos que tenha dual-boot com o Windows." 12 50 30 "utc" "" ON "localtime" "" OFF --stdout)

# Definir Senha Root
root_password

# Criar Novo Usuário
USER=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Criar Novo Usuário " --inputbox "\nDigite o nome do usuário. As letras DEVEM ser minúsculas.\n" 10 50 --stdout)
user_password

automatic_particao

#### Instalcao
config_install
install_base
config_base
install_boot

reboote
