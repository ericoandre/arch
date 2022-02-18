#!/bin/bash

##################################################
#                   Variaveis                    #
##################################################

# Architecture
ARCHI=$(uname -m)
SYSTEM="Unknown"
VERSION="Arch Linux Installer"

# Pacote 

# Pacote a serem Instalados
BASE_PACKAGES=('base' 'base-devel' 'grub' 'sudo' 'nano')

# Pacote extras (não são obrigatórios)
BASE_EXTRAS=('ntfs-3g' 'exfat-utils' 'os-prober' 'dosfstools' 'mtools' 'acpi' 'acpid' 'zsh' 'zsh-syntax-highlighting' 'zsh-autosuggestions')
BASE_EXTRAS+=('unrar' 'tar' 'alsa-plugins' 'alsa-utils' 'alsa-firmware' 'pulseaudio' 'pulseaudio-alsa' 'pavucontrol' 'volumeicon' 'cmatrix')
BASE_EXTRAS+=('dbus' 'ufw' 'traceroute' 'networkmanager' 'net-tools' 'scrot' 'neofetch' 'iw' 'bash-completion' 'iptables')
BASE_EXTRAS+=('archlinux-keyring' 'wget' 'make' 'gcc' 'htop' 'git' 'pciutils' 'openbsd-netcat' 'nmap' 'ntp')

FONTES_PKGS=('ttf-droid' 'noto-fonts' 'ttf-liberation' 'ttf-freefont' 'ttf-dejavu' 'ttf-hack' 'ttf-roboto' 'freetype2' 'terminus-font' 'ttf-bitstream-vera' 'ttf-dejavu' 'ttf-droid' 'ttf-fira-mono' 'ttf-fira-sans' 'ttf-freefont' 'ttf-inconsolata' 'ttf-liberation' 'ttf-linux-libertine' 'ttf-ubuntu-font-family' 'ttf-font-awesome' 'otf-font-awesome')

DESKTOP_DEFAULTS=('xorg' 'xorg-xkbcomp' 'xorg-xinit' 'xorg-server' 'xorg-twm' 'xorg-xclock' 'xorg-drivers' 'xorg-xkill' 'xorg-fonts-100dpi' 'xorg-fonts-75dpi' 'xorg-xfontsel' 'mesa' 'xterm')
DESKTOP_DEFAULTS+=('tilix' 'libreoffice-fresh' 'vlc' 'lollypop' 'firefox' 'leafpad' 'firefox' 'xscreensaver') 
DESKTOP_DEFAULTS+=('nodejs' 'npm' 'yarn' 'python' 'python-pip')
DESKTOP_DEFAULTS+=('adwaita-icon-theme' 'papirus-icon-theme' 'oxygen-icons' 'faenza-icon-theme' 'breeze-icons')
DESKTOP_DEFAULTS+=('archlinux-wallpaper' 'xdg-user-dirs-gtk' 'audacious') 

DESKTOP_PACKAGES=()

# Config Suport
KERNEL=linux
HNAME=ArchVM
KEYMAP=br-abnt2
ZONE=America
SUBZONE=Recife
LOCALE=pt_BR.UTF-8
FONT=lat0-16
CLOCK=utc
USER=erico
ROOT_PASSWD=toorrico
USER_PASSWD=toor
XKBMAP=br

########## Variáveis Para Particionamento do Disco
# ATENÇÃO, este script apaga TODO o conteúdo do disco especificado em $HD.
HD=/dev/sda
# Ponto de Montagem para o novo sistema
MOINTPOINT=/mnt
# Tamanho da Partição Boot: /boot
BOOT_SIZE=512
# Tamanho da Partição Root: /
ROOT_SIZE=10000
# Tamanho da Partição Swap:
SWAP_SIZE=2000
# A partição /home irá ocupar o restante do espaço livre em disco

# File System das partições
EFI_FS=fat32
BOOT_FS=ext2
ROOT_FS=ext4

######## Variáveis auxiliares. NÃO DEVEM SER ALTERADAS
BOOT_START=1
BOOT_END=$(($BOOT_START+$BOOT_SIZE))

SWAP_START=$BOOT_END
SWAP_END=$(($SWAP_START+$SWAP_SIZE))

ROOT_START=$SWAP_END
ROOT_END=$(($ROOT_START+$ROOT_SIZE))

########
SWAPFILE=false
dm_enabled=false
bluetooth_enabled=false
mounted=true

xinit_config=''
DESKTOP=''
GUI=''
DM=''

if [[ $SWAPFILE -eq false ]] ; then
        ROOT_DEVICE=${HD}3
else
        ROOT_DEVICE=${HD}2
fi

# Check for UEFI
[[ -d /sys/firmware/efi ]] && UEFI=true

# Check for bluetooth support
if dmesg | grep -iq "blue"; then
        bluetooth=true
fi

##################################################
#                   functions                    #
##################################################

##### ------------------------------------
arch_chroot() {
    arch-chroot $MOINTPOINT /bin/bash -c "${1}" &> /dev/null
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
reboot_system(){
    if $installed; then
        while true; do
            choice=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Reboot System" --nocancel --menu "Arch Linux has finished installing.\nYou must restart your \
                system to boot Arch.\n\nPlease select one of the following options:" 13 60 3 \
                "Reboot" "Reboot system" \
                "Poweroff" "Poweroff system" \
                "Exit" "Unmount system and exit to CLI" --stdout)

            dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --infobox "Unmounting partitions on ${MOINTPOINT}..." 3 50
            umount -R $MOINTPOINT
            case "$choice" in
                "Reboot") reset ; reboot ; exit ;;
                "Poweroff") reset ; poweroff ; exit ;;
                "Exit") reset ; exit ;;
            esac
        done
    else
        dialog --title "Reboot System" --yesno "The installation is incomplete.\n\nAre you sure you want to reboot your system?" 7 60
        if [ $? -eq 0 ]; then
            reset ; reboot ; exit
        fi
    fi
}

##### drivers ----------------------------
# VM
install_driver_virt() {
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
# Videos
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

##### ------------------------------------
# Crieando um rótulo para partição do disco selecionado
inicializa_hd() {
        echo "Inicializando o HD"
        # Configura o tipo da tabela de partições (Ignorando erros)
        if $UEFI ; then
                parted -s $HD mklabel gpt &> /dev/null
        else
                parted -s $HD mklabel msdos &> /dev/null
        fi
}
particiona_discos() {
        ERR=0

        # Cria partição boot
        echo "Criando partição boot"
        if $UEFI ; then
                parted -s $HD mkpart primary $EFI_FS $BOOT_START $BOOT_END 1>/dev/null || ERR=1
                parted -s $HD set 1 esp on 1>/dev/null || ERR=1
        else
                parted -s $HD mkpart primary $BOOT_FS $BOOT_START $BOOT_END 1>/dev/null || ERR=1
                parted -s $HD set 1 boot on 1>/dev/null || ERR=1
        fi

        if [[ $SWAPFILE -eq false ]] ; then
                # Cria partição swap
                echo "Criando partição swap"
                parted -s $HD mkpart primary linux-swap $SWAP_START $SWAP_END 1>/dev/null || ERR=1
        fi

        # Cria partição root
        echo "Criando partição root"
        parted -s -- $HD mkpart primary $ROOT_FS $ROOT_START -0 1>/dev/null || ERR=1

        if [[ $ERR -eq 1 ]]; then
                echo "Erro durante o particionamento"
                exit 1
        fi
}
cria_fs() {
        ERR=0
        echo "Formatando partição boot"
        if $UEFI ; then
                mkfs.vfat -F32 -n BOOT ${HD}1 1>/dev/null || ERR=1
        else
                mkfs.$BOOT_FS ${HD}1 1>/dev/null || ERR=1
        fi
        if [[ $SWAPFILE -eq false ]]; then 
                # Cria e inicia a swap
                echo "Formatando partição swap"
                mkswap ${HD}2 || ERR=1
        fi
        echo "Formatando partição root"
        mkfs.$ROOT_FS $ROOT_DEVICE -L Root 1>/dev/null || ERR=1

        if [[ $ERR -eq 1 ]]; then
                echo "Erro ao criar File Systems"
                exit 1
        fi 
}
monta_particoes() {
        ERR=0
        echo "Montando partições"
        # Monta partição root
        mount $ROOT_DEVICE /mnt || ERR=1
        if $UEFI ; then
                # Monta partição efi
                mkdir -p ${MOINTPOINT}/boot/efi || ERR=1
                mount ${HD}1 ${MOINTPOINT}/boot/efi || ERR=1
        else
                # Monta partição boot
                mkdir ${MOINTPOINT}/boot || ERR=1
                mount ${HD}1 ${MOINTPOINT}/boot || ERR=1
        fi
        [[ $SWAPFILE -eq false ]] && swapon ${HD}2 || ERR=1

        if [[ $ERR -eq 1 ]]; then
                echo "Erro ao Montar as partição"
                exit 1
        fi
}
##### ------------------------------------
update_mirrorlist() {
        ERR=0
        pacman -Sy --noconfirm reflector &> /dev/null
        reflector --verbose --protocol http --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
        [[ "$(uname -m)" = "x86_64" ]] && sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf && pacman -Sy
}
configure_instalando_sistema(){
        [[ $UEFI ]] && BASE_EXTRAS+=('efibootmgr')

        if [ "$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')" = "GenuineIntel" ]; then
                BASE_EXTRAS+=('intel-ucode')
        elif [ "$proc" = "AuthenticAMD" ]; then
                BASE_EXTRAS+=('amd-ucode')
        fi
        while true; do
                DESKTOP=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Choose your Graphical Environment" --no-cancel --menu "Select the style of graphical environment you wish to \
                        use.\n\nGraphical environment:" 12 75 3 \
                        "Desktop Environment" "Traditional complete graphical user interface" \
                        "Window Manager" "Standalone minimal graphical user interface" \
                        "None" "Command-line only interface" --stdout)
                if [ "$DESKTOP" = "Desktop Environment" ]; then
                        GUI=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Select a Desktop Environment" --menu "Select a desktop environment to install:" 15 65 8 \
                                "GNOME SHELL" "Modern MiNIMAL simplicity focused desktop" \
                                "KDE Plasma" "Full featured QT based desktop" \
                                "LXDE" "Lightweight and efficient desktop" \
                                "LXQT" "Lightweight and efficient QT based desktop" \
                                "Xfce" "Lightweight and modular desktop" --stdout)
                        [[ $? -eq 0 ]] && break
                elif [ "$DESKTOP" = "Window Manager" ]; then 
                        GUI=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "Select a Window Manager" --menu "Select a window manager to install:" 13 75 6 \
                                "awesome" "Highly configurable, dynamic window manager" \
                                "bspwm" "Tiling window manager based on binary space partitioning" \
                                "Fluxbox" "Stacking window manager based on Blackbox" \
                                "i3" "Dynamic tiling window manager inspired by wmii" \
                                "Openbox" "Highly configurable, stacking window manager" \
                                "xmonad" "Dynamic tiling window manager configured in Haskell" --stdout)
                        [[ $? -eq 0 ]] && break
                else
                        break
                fi
        done

        if [ "$DESKTOP" != "None" ]; then
                DESKTOP_PACKAGES+=("${DESKTOP_DEFAULTS[@]}")
                case "$GUI" in
                        "GNOME SHELL") 
                        DESKTOP_PACKAGES+=('gnome-shell' 'gnome-backgrounds' 'gnome-control-center' 'gnome-screenshot' 'gnome-system-monitor' 'gnome-terminal' 'gnome-tweak-tool' 'nautilus' 'gvfs' 'gnome-calculator' 'gnome-disk-utility') 
                        xinit_config="exec gnome-session" 
                        ;;
                        "KDE Plasma") 
                        DESKTOP_PACKAGES+=('plasma' 'dolphin' 'plasma-wayland-session' 'konsole' 'kate' 'kcalc' 'ark' 'gwenview' 'spectacle' 'okular' 'packagekit-qt5') 
                        xinit_config="exec startkde"
                        ;;
                        "LXDE") 
                        DESKTOP_PACKAGES+=('lxde') 
                        xinit_config="exec startlxde"
                        ;;
                        "LXQT") 
                        DESKTOP_PACKAGES+=('lxqt' 'xdg-utils' 'libpulse' 'libstatgrab' 'libsysstat' 'lm_sensors' 'pavucontrol-qt') 
                        xinit_config="exec startlxqt"
                        ;;
                        "Xfce") 
                        DESKTOP_PACKAGES+=('xfce4' 'xfce4-goodies') 
                        xinit_config="exec startxfce4"
                        ;;
                        "awesome") 
                        DESKTOP_PACKAGES+=('awesome') 
                        xinit_config="exec awesome"
                        ;;
                        "bspwm") 
                        DESKTOP_PACKAGES+=('bspwm' 'sxhkd') 
                        xinit_config="sxhkd & ; exec bspwm"
                        ;; # 
                        "Fluxbox") 
                        DESKTOP_PACKAGES+=('fluxbox') 
                        xinit_config="exec startfluxbox"
                        ;;
                        "i3") 
                        DESKTOP_PACKAGES+=('i3') 
                        xinit_config="exec i3"
                        ;;
                        "Openbox") 
                        DESKTOP_PACKAGES+=('openbox') 
                        xinit_config="exec openbox-session"
                        ;;
                        "xmonad") 
                        DESKTOP_PACKAGES+=('xmonad' 'xmonad-contrib') 
                        xinit_config="exec xmonad"
                        ;;
                esac
                # GNOME already has networkmanager applet built-in. Plasma uses plasma-nm
                if [ "$GUI" != "GNOME" ]; then
                        if [ "$GUI" = "KDE Plasma" ]; then
                                DESKTOP_PACKAGES+=('plasma-nm')
                        else
                                DESKTOP_PACKAGES+=('network-manager-applet' 'gnome-keyring')
                        fi
                fi

                # Check for available bluetooth devices
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

                dialog --title "Install a Display Manager" --yesno "Would you like to install a graphical login manager?\n\nIf you select no, 'xinit' will be installed so you can manually start Xorg with the'startx' command." 8 60
                if [ $? -eq 0 ]; then
                        DM=$(dialog  --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)"  --title "Install a Display Manager" --menu "Select a display manager to install:" 10 50 3 "gdm" "GNOME Display Manager" "lxdm" "" "lightdm" "Lightweight Display Manager" "sddm" "Simple Desktop Display Manager" --stdout)
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
        fi
}
instalando_sistema() {
        ERR=0

        [[ $UEFI ]] && BASE_EXTRAS+=('efibootmgr')

        if [ "$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')" = "GenuineIntel" ]; then
                BASE_EXTRAS+=('intel-ucode')
        elif [ "$proc" = "AuthenticAMD" ]; then
                BASE_EXTRAS+=('amd-ucode')
        fi

        echo "Rodando pactrap base base-devel ${KERNEL}"
        pacstrap $MOINTPOINT "${BASE_PACKAGES[@]}" ${KERNEL} ${KERNEL}-headers ${KERNEL}-firmware "${BASE_EXTRAS[@]}" "${FONTES_PKGS[@]}" "${DESKTOP_PACKAGES[@]}" || ERR=1
        if [[ $ERR -eq 1 ]]; then
                echo "Erro ao instalar sistema ${KERNEL}"
                exit 1
        fi
}
config_base() {
        ERR=0
        # Configura hostname
        echo ${HNAME} > ${MOINTPOINT}/etc/hostname || ERR=1
        echo -e "127.0.0.1    localhost.localdomain    localhost\n::1        localhost.localdomain    localhost\n127.0.1.1    $HNAME.localdomain    $HNAME" >> ${MOINTPOINT}/etc/hosts || ERR=1

        # Configura locale.conf locales setting locale pt_BR.UTF-8 UTF-8
        echo "locale.conf"
        echo -e "LANG=${LOCALE}\nLC_MESSAGES=${LOCALE}" > ${MOINTPOINT}/etc/locale.conf || ERR=1

        # Configura locale.gen
        echo "locale.gen"
        sed -i "s/#${LOCALE}/${LOCALE}/" ${MOINTPOINT}/etc/locale.gen || ERR=1
        arch_chroot "locale-gen" 
        arch_chroot "export LANG=${LOCALE}"

        # Configura layout do teclado
        echo "vconsole"
        echo -e "KEYMAP=${KEYMAP}\nFONT=${FONT}\nFONT_MAP=" > ${MOINTPOINT}/etc/vconsole.conf  || ERR=1

        # Configura hora Setting hw CLOCK
        arch_chroot "hwclock --systohc --${CLOCK}" 

        # Setting timezone
        echo "timezone"
        arch_chroot "ln -s /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime" 

        # root password
        #root_password
        arch_chroot "echo -e $ROOT_PASSWD'\n'$ROOT_PASSWD | passwd"
        #user_password

        # criar usuario Definir senha do usuário
        arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash ${USER}" 
        arch_chroot "echo -e $USER_PASSWD'\n'$USER_PASSWD | passwd `echo $USER`" 

        # fstab
        genfstab -U -p $MOINTPOINT > ${MOINTPOINT}/etc/fstab || ERR=1

        # networkmanager acpi
        echo "enable networkmanager acpi"
        arch_chroot "systemctl enable NetworkManager.service acpid.service ntpd.service" 

        [[ bluetooth_enabled ]] && arch_chroot "systemctl enable bluetooth.service"


        echo "driver e Display Manager"
        install_driver_virt
        if [[ "$DESKTOP" != "None" ]]; then 
                install_driver_videos
                [[ $dm_enabled ]] && arch_chroot "systemctl enable ${DM}.service" || echo "$xinit_config" > ${MOINTPOINT}/home/"$USER"/.xinitrc
        fi

        # Configura ambiente ramdisk inicial
        echo "Configura ambiente ramdisk inicial"
        arch_chroot "mkinitcpio -p ${KERNEL}"

        if [[ $ERR -eq 1 ]]; then
                echo "Erro ao config base"
                exit 1
        fi     
}
install_boot_grub() {
        echo "Boot Grub"
        if $UEFI ; then
                arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck"
                [[ -d ${MOINTPOINT}/boot/efi/EFI/boot ]] &&  echo "Directory EFI/boot found." || mkdir ${MOINTPOINT}/boot/efi/EFI/boot 
                cp ${MOINTPOINT}/boot/efi/EFI/GRUB/grubx64.efi ${MOINTPOINT}/boot/efi/EFI/boot/bootx64.efi
        else
                arch_chroot "grub-install --target=i386-pc --recheck $HD"
        fi
        [[ -d ${MOINTPOINT}/boot/grub/locale ]] &&  echo "Directory grub/locale found." || mkdir ${MOINTPOINT}/boot/grub/locale
        cp ${MOINTPOINT}/usr/share/locale/en@quot/LC_MESSAGES/grub.mo ${MOINTPOINT}/boot/grub/locale/en.mo
        arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}

##################################################
#                   Script                       #
##################################################

pacman -Sy --noconfirm dialog &> /dev/null

#### Particionamento
inicializa_hd
particiona_discos
cria_fs
monta_particoes

#### Instalação
update_mirrorlist
# configure_instalando_sistema
instalando_sistema
config_base
install_boot_grub

#### 
# reboot_system