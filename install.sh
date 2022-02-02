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
KERNEL=linux

# Language Support
CURR_LOCALE=pt_BR.UTF-8
FONT=lat0-16
KEYMAP=br-abnt2
XKBMAP=""
ZONE=America
SUBZONE=Recife
CLOCK=utc
HNAME=ArchVM

# Installation
MOUNTPOINT=/mnt
HD=/dev/sda

SWAP_SIZE=1024
BOOT_SIZE=512
ROOT_SIZE=0

BOOT_FS=ext2
ROOT_FS=ext4

EXTRA_PKGS="ntp sudo go ibus dbus dbus-glib dbus-python python python-pip scrot screenfetch wget cmatrix gcc htop make jre8-openjdk jre8-openjdk-headless git ntfs-3g os-prober pciutils acpi acpid unrar p7zip tar rsync ufw iptables openbsd-netcat traceroute nmap exfat-utils networkmanager iw net-tools dhclient dhcpcd neofetch nano alsa-plugins alsa-utils alsa-firmware pulseaudio pulseaudio-alsa pavucontrol volumeicon bash-completion zsh zsh-syntax-highlighting zsh-autosuggestions ttf-droid noto-fonts  ttf-liberation ttf-freefont ttf-dejavu ttf-hack ttf-roboto"

######## Variáveis auxiliares. NÃO DEVEM SER ALTERADAS
BOOT_START=1
BOOT_END=$(($BOOT_START+$BOOT_SIZE))

SWAP_START=$BOOT_END
SWAP_END=$(($SWAP_START+$SWAP_SIZE))

ROOT_START=$SWAP_END
ROOT_END=$(($ROOT_START+$ROOT_SIZE))

if [[ -d "/sys/firmware/efi/" ]]; then
    SYSTEM="UEFI"
else
    SYSTEM="BIOS"
fi

######################################################################
##                                                                  ##
##                 Configuration Functions							##
##                                                                  ##
######################################################################

arch_chroot() {
    arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
}  
Parted() {
    parted --script $HD "${1}"
}

automatic_particao() {
    if [[ "$SYSTEM" -eq "UEFI" ]]; then
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
    
    dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Criar Swap " --clear --yesno "\nCriar memoria de paginação Swap em arquivo?" 7 50
    if [[ $? -eq 1 ]]; then
      # Cria partição swap
      parted -s $HD mkpart primary linux-swap $SWAP_START $SWAP_END
      Parted "mkpart primary $ROOT_FS $ROOT_START -$ROOT_END"
      MOUNTPOINTROOT=3
    else
      Parted "mkpart primary $ROOT_FS $BOOT_END -$ROOT_END"
      MOUNTPOINTROOT=2
    fi
    
    # Formatando partição root
    mkfs.$ROOT_FS ${HD}${MOUNTPOINTROOT} -L Root
    mount ${HD}${MOUNTPOINTROOT} $MOUNTPOINT

    if [[ $MOUNTPOINTROOT -eq 2 ]]; then
      mkdir -p  $MOUNTPOINT/opt/swap && touch $MOUNTPOINT/opt/swap/swapfile
      dd if=/dev/zero of=$MOUNTPOINT/opt/swap/swapfile bs=1M count=$SWAP_SIZE status=progress
      chmod 600 $MOUNTPOINT/opt/swap/swapfile
      mkswap $MOUNTPOINT/opt/swap/swapfile
      swapon $MOUNTPOINT/opt/swap/swapfile
    else
      mkswap ${HD}2
      swapon ${HD}2
    fi
    
    if [[ "$SYSTEM" -eq "UEFI" ]]; then
        # Monta partição esp
        mkdir -p $MOUNTPOINT/boot/efi && mount $HD1 $MOUNTPOINT/boot/efi
    else
        # Monta partição boot
        mkdir -p $MOUNTPOINT/boot && mount $HD1 $MOUNTPOINT/boot
    fi
}

reboote(){
    dialog --clear --title " Installation finished sucessfully " --yesno "\nDo you want to reboot?" 7 62
    if [[ $? -eq 0 ]]; then
        echo "System will reboot in a moment..."
        sleep 3
        clear
        umount -R $MOUNTPOINT
        reboot
    fi
}

install_driver() {
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
    pacstrap ${MOUNTPOINT} xf86-input-synaptics synaptic
}

install_driver_videos() {
    if grep -E "NVIDIA|GeForce" <<< $(lspci); then
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

install_descktopmanager() {
    install_driver_videos
    arch_chroot "pacman -Sy xorg xorg-xkbcomp xorg-xinit xorg-server xorg-twm xorg-xclock xorg-xinit xorg-drivers xorg-xkill xorg-fonts-100dpi xorg-fonts-75dpi mesa xterm --noconfirm --needed"
    desktop=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --menu "Desktop Environment" 15 50 50  1 "Gnome Minimal" 2 "Gnome" 3 "Plasma kde" 4 "cinnamon" 5 "xfce4" 6 "deepin" 7 "LXQt" 8 "Minimal"  --stdout)
    case $desktop in
        1)
          DEpkg="gdm gnome-shell gnome-backgrounds gnome-control-center gnome-screenshot gnome-system-monitor gnome-terminal gnome-tweak-tool nautilus gedit gvfs gnome-calculator gnome-disk-utility"
          DMANAGER=1
          ;;
        2)
          DEpkg="gdm gnome gnome-tweak-tool "
          DMANAGER=1
          ;;
        3)
          DEpkg="sddm plasma plasma-wayland-session dolphin konsole kate kcalc ark gwenview spectacle okular packagekit-qt5 "
          DMANAGER=2
          ;;
        4)
          DEpkg="gdm cinnamon sakura gnome-disk-utility nemo-fileroller mousepad gnome-software gnome-system-monitor gnome-screenshot network-manager-applet "
          DMANAGER=1
          ;;
        5)
          DEpkg="lxdm xfce4 xfce4-goodies network-manager-applet file-roller leafpad "
          DMANAGER=3
          ;;
        6)
          DEpkg="lightdm lightdm-webkit2-greeter accountsservice deepin deepin-extra ark gnome-disk-utility gedit "
          DMANAGER=4
          ;;
        7)
          DEpkg="lxdm lxqt xdg-utils libpulse libstatgrab libsysstat lm_sensors network-manager-applet pavucontrol-qt "
          DMANAGER=3
          ;;
    esac
    arch_chroot "pacman -Sy $DEpkg audacious pulseaudio pulseaudio-alsa pavucontrol xscreensaver vlc archlinux-wallpaper libreoffice-fresh tilix mesa eog gparted xdg-user-dirs-gtk firefox evince adwaita-icon-theme papirus-icon-theme oxygen-icons faenza-icon-theme --noconfirm --needed"
    case $DMANAGER in
        1)
          arch_chroot "systemctl enable gdm.service"
          ;;
        2)
          arch_chroot "echo -e '[Theme]\nCurrent=breeze' >> /usr/lib/sddm/sddm.conf.d/default.conf"
          arch-chroot "systemctl enable sddm.service"
          ;; 
        3)
          arch-chroot "systemctl enable lxdm.service"
          ;;
        4)
          wget git.io/webkit2 -O tema.tar.gz && mkdir -p $MOUNTPOINT/usr/share/lightdm-webkit/themes/glorious
          tar zxvf tema.tar.gz -C $MOUNTPOINT/usr/share/lightdm-webkit/themes/glorious
          echo "webkit_theme=glorious" >> $MOUNTPOINT/etc/lightdm/lightdm-webkit2-greeter.conf
          arch-chroot "systemctl enable lightdm.service"
          ;;
          
    esac
}

install_root() {
    KERNEL=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)"  --title "$TITLE" --radiolist "Existem vários kernels disponíveis para o sistema.\n\nO mais comum é o atual kernel linux.\nEste kernel é o mais atualizado, oferecendo o melhor suporte de hardware.\nNo entanto, pode haver possíveis erros nesse kernel, apesar dos testes.\n\nO kernel linux-lts fornece um foco na estabilidade.\nEle é baseado em um kernel mais antigo, por isso pode não ter alguns recursos mais recentes.\n\nO kernel com proteção do linux é focado na segurança \nEle contém o Grsecurity Patchset e o PaX para aumentar a segurança. \n\nO kernel do linux-zen é o resultado de uma colaboração de hackers do kernel \npara fornecer o melhor kernel possível para os sistemas cotidianos. \n\nPor favor, selecione o kernel que você deseja instalar." 50 100 100 linux "" on linux-lts "" off linux-hardened "" off linux-zen "" off --stdout)
    reflector --verbose --protocol http --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
    [[ "$(uname -m)" = "x86_64" ]] && sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf 
    pacman -Sy
    pacstrap ${MOUNTPOINT} base base-devel ${KERNEL} ${KERNEL}-headers ${KERNEL}-firmware grub `echo $EXTRA_PKGS`
    
    genfstab -U -p $MOUNTPOINT >> $MOUNTPOINT/etc/fstab
    
    #### networkmanager acpi
    arch_chroot "systemctl enable NetworkManager.service acpid.service ntpd.service"
    
    cp /etc/pacman.d/mirrorlist ${MOUNTPOINT}/etc/pacman.d/mirrorlist
    [[ "$(uname -m)" = "x86_64" ]] && sed -i '/multilib\]/,+1 s/^#//' $MOUNTPOINT/etc/pacman.conf
    git clone https://aur.archlinux.org/yay.git $MOUNTPOINT/tmp
}

install_bootloader() {
    #### Install Bootloader
    if [ "$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')" = "GenuineIntel" ]; then
        pacstrap $MOUNTPOINT intel-ucode
    elif [ "$proc" = "AuthenticAMD" ]; then
        pacstrap $MOUNTPOINT amd-ucode
    fi
    
    # Configura ambiente ramdisk inicial
    arch_chroot "mkinitcpio -p ${KERNEL}"
    if [[ "$SYSTEM" -eq "UEFI"  ]]; then
        arch_chroot "pacman -S --noconfirm efibootmgr dosfstools mtools"
        arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck"
        mkdir $MOUNTPOINT/boot/efi/EFI/boot && mkdir $MOUNTPOINT/boot/grub/locale
        cp $MOUNTPOINT/boot/efi/EFI/grub_uefi/grubx64.efi $MOUNTPOINT/boot/efi/EFI/boot/bootx64.efi
    else
        arch_chroot "grub-install --target=i386-pc --recheck $HD"
    fi
    cp $MOUNTPOINT/usr/share/locale/en@quot/LC_MESSAGES/grub.mo $MOUNTPOINT/boot/grub/locale/en.mo
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}


######################################################################
##                                                                  ##
##                            Execution                             ##
##                                                                  ##
######################################################################

timedatectl set-ntp true
[[ $FONT != "" ]] && setfont $FONT
loadkeys $KEYMAP  # br-abnt2

#### Particionamento esta configurado para usar todo o hd
automatic_particao

#### Instalcao
install_root
install_driver
install_bootloader

#### configure base system
CURR_LOCALE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir a Localização do Sistema " --menu "A localização (locale) determina o idioma a ser exibido, os formatos de data e hora, etc...\n\nO formato é idioma_PAÍS (ex.: en_US é inglês, Estados Unidos; pt_PT é português, Portugal)." 0 0 12 $(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 | sort | awk '{ printf $0 " - " }') --stdout)

# Set the installed system's hostname
HNAME=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Nome da Máquina " --inputbox "\nO hostname é usado para identificar o sistema em uma rede.\n\nE é restrito aos caracteres alfa numéricos, pode conter um hifen (-) - mas não no inicio ou no fim - e não deve ser maior que 63 caracteres.\n" 15 60 --stdout)

# Set Zone and Sub-Zone
ZONE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --menu "\nO fuso horário é usado para definir correctamente o relógio do sistema." 20 50 50 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud | sort | awk '{ printf ""$0""  " - " }') --stdout)
SUBZONE=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --menu "\nSeleccione a cidade mais próxima de você." 20 50 50 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "$ZONE/" | sed "s/$ZONE\///g" | sort -ud | sort | awk '{ printf ""$0""  " - " }') --stdout)

CLOCK=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Fuso horário e Relógio " --radiolist "\nUTC é o padrão de tempo universal e é recomendado a menos que tenha dual-boot com o Windows." 12 50 30 "utc" "" ON "localtime" "" OFF --stdout)

# Definir Senha Root
ROOT_PASSWD=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Definir Senha ROOT " --inputbox "\nDigite a senha Root \n\n" 10 50 --stdout)

# Criar Novo Usuário
USER=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Criar Novo Usuário " --inputbox "\nDigite o nome do usuário. As letras DEVEM ser minúsculas.\n" 10 50 --stdout)
USER_PASSWD=$(dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Adicionar Novo Usuário " --inputbox "\nInsira a senha para $USER" 10 50 --stdout)

#### configure base system
dialog --clear --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "INTEFACE GRAFICA" --clear --yesno "\nDeseja Instalar Windows Manager ?" 7 50
if [[ $? -eq 0 ]]; then
    install_driver_videos
    install_descktopmanager
fi

#### setting hostname
echo $HNAME > $MOUNTPOINT/etc/hostname
echo -e "127.0.0.1    localhost.localdomain    localhost\n::1        localhost.localdomain    localhost\n127.0.1.1    $HNAME.localdomain    $HNAME" >> $MOUNTPOINT/etc/hosts

#### locales setting locale pt_BR.UTF-8 UTF-8
echo -e "LANG=$LOCALE\nLC_MESSAGES=$LOCALE" > $MOUNTPOINT/etc/locale.conf
sed -i "s/#$LOCALE/$LOCALE/" $MOUNTPOINT/etc/locale.gen
arch_chroot "locale-gen"
arch_chroot "export LANG=$LOCALE"

#### virtual console keymap
echo -e "KEYMAP=$KEYMAP\nFONT=$FONT" > $MOUNTPOINT/etc/vconsole.conf

#### Setting timezone
arch_chroot "ln -s /usr/share/zoneinfo/$ZONE/$SUBZONE /etc/localtime"

#### Setting hw CLOCK
arch_chroot "hwclock --systohc --$CLOCK"

#### root password
arch_chroot "echo -e $ROOT_PASSWD'\n'$ROOT_PASSWD | passwd"

#### criar usuario Definir senha do usuário 
arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash ${USER}"
arch_chroot "echo -e $USER_PASSWD'\n'$USER_PASSWD | passwd `echo $USER`"
arch_chroot "sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers"

reboote
