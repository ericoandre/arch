#!/usr/bin/env bash

##################################################
#                   Variaveis                    #
##################################################

LANGUAGE=pt_BR.UTF-8
KEYBOARD_LAYOUT=br-abnt2

HD=/dev/sda

SWAP_SIZE=1024
BOOT_SIZE=512
ROOT_SIZE=0

EXTRA_PKGS="sudo go screenfetch wget cmatrix gcc htop make jre8-openjdk jre8-openjdk-headless openbsd-netcat traceroute git ntfs-3g os-prober virtualbox-guest-utils pciutils acpi acpid dbus unrar p7zip tar rsync ufw exfat-utils networkmanager iw net-tools dhclient dhcpcd neofetch nano alsa-plugins alsa-utils alsa-firmware pulseaudio pulseaudio-alsa pavucontrol volumeicon bash-completion zsh zsh-syntax-highlighting zsh-autosuggestions"

######## Variáveis auxiliares. NÃO DEVEM SER ALTERADAS
BOOT_START=1
BOOT_END=$(($BOOT_START+$BOOT_SIZE))

ROOT_START=$BOOT_END
if [[ $ROOT_SIZE -eq 0 ]]; then
  ROOT_END=-0
else
  ROOT_END=$(($ROOT_START+$ROOT_SIZE))
fi

##################################################
#                   functions                    #
##################################################

arch_chroot(){
  arch-chroot /mnt /bin/bash -c "${1}"
}
Parted() {
  parted --script $HD "${1}"
}
particionar_discos(){
  if [[ -d "/sys/firmware/efi/" ]]; then
    # Configura o tipo da tabela de partições
    Parted "mklabel gpt"
    Parted "mkpart primary fat32 $BOOT_START $BOOT_END"
    Parted "set 1 esp on"
  else
    # Configura o tipo da tabela de partições
    Parted "mklabel msdos"
    Parted "mkpart primary ext2 $BOOT_START $BOOT_END"
    Parted "set 1 bios_grub on"
  fi

  Parted "mkpart primary $ROOT_FS $ROOT_START $ROOT_END"
}
monta_particoes(){
  # Formatando partição root
  mkfs.ext4 /dev/sda2 -L Root
  mount /dev/sda2 /mnt

  if [[ -d "/sys/firmware/efi/" ]]; then
    # Monta partição esp
    mkfs.vfat -F32 -n BOOT /dev/sda1
    mkdir -p /mnt/boot/efi && mount /dev/sda1 /mnt/boot/efi
  else
    # Monta partição boot
    mkfs.ext2 /dev/sda1
    mkdir -p /mnt/boot && mount /dev/sda1 /mnt/boot
  fi

  mkdir -p  /mnt/opt/swap && touch /mnt/opt/swap/swapfile
  dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=$SWAP_SIZE status=progress
  chmod 600 /mnt/opt/swap/swapfile
  mkswap /mnt/opt/swap/swapfile
  swapon /mnt/opt/swap/swapfile
}

conf_repositorio(){
  reflector --verbose --protocol http --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
  if [ "$(uname -m)" = "x86_64" ]; then
    sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf
  fi
  pacman -Sy
}

inst_base(){
  #### Install base system
  # pacstrap /mnt base bash nano vim-minimal vi linux-firmware cryptsetup e2fsprogs findutils gawk inetutils iproute2 jfsutils licenses linux-firmware logrotate lvm2 man-db man-pages mdadm pciutils procps-ng reiserfsprogs sysfsutils xfsprogs usbutils `echo $kernel`
  pacstrap /mnt base base-devel linux linux-headers linux-firmware ttf-liberation ttf-dejavu ttf-hack ttf-roboto grub `echo $EXTRA_PKGS`
  
  #### fstab
  genfstab -U -p /mnt >> /mnt/etc/fstab
  echo "/opt/swap/swapfile             none    swap    sw        0       0" >> /mnt/etc/fstab
  
  cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
  if [ "$(uname -m)" = "x86_64" ]; then
    sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf
  fi
}

inst_boot_load(){
    proc=$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')
    if [ "$proc" = "GenuineIntel" ]; then
        pacstrap /mnt intel-ucode
    elif [ "$proc" = "AuthenticAMD" ]; then
        pacstrap /mnt amd-ucode
    fi
    
    arch_chroot "mkinitcpio -p linux"

    if [[ -d "/sys/firmware/efi/" ]]; then
        arch_chroot "pacman -S --noconfirm efibootmgr dosfstools mtools"
        arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub_uefi --recheck"
        mkdir /mnt/boot/efi/EFI/boot && mkdir /mnt/boot/grub/locale
        cp /mnt/boot/efi/EFI/grub_uefi/grubx64.efi /mnt/boot/efi/EFI/boot/bootx64.efi
    else
        arch_chroot "grub-install --target=i386-pc --recheck $HD"
    fi
    cp /mnt/usr/share/locale/en@quot/LC_MESSAGES/grub.mo /mnt/boot/grub/locale/en.mo
    arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
}
##################################################
#                   Script                       #
##################################################

pacman -Syy && pacman -S --noconfirm dialog terminus-font reflector

timedatectl set-ntp true
loadkeys br-abnt2
setfont ter-v22b

#### Particionamento esta configurado para usar todo o hd
particionar_discos
monta_particoes

#### Instalcao
conf_repositorio

inst_base
inst_boot_load

#### Configuracao
arch_chroot "loadkeys br-abnt2"
arch_chroot "timedatectl set-ntp true"

HNAME=$(dialog  --clear --inputbox "Digite o nome do Computador" 10 25 --stdout)

ZONE=$(dialog  --clear --menu "Select Sua country/zone." 20 35 15 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud | sort | awk '{ printf "\0"$0"\0"  " . " }') --stdout)
SUBZONE=$(dialog  --clear --menu "Select Sua country/zone." 20 35 15 $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "$ZONE/" | sed "s/$ZONE\///g" | sort -ud | sort | awk '{ printf "\0"$0"\0"  " . " }') --stdout)

LANGUAGE=$(dialog  --clear --radiolist "Escolha idioma do sistema:" 15 30 4 $(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 | sort | awk '{ print $0 "\"\"  OFF " }') --stdout)
CLOCK=$(dialog  --clear --radiolist "Configurcao do relojo" 10 30 4 "utc" "" ON "localtime" "" OFF --stdout)

ROOT_PASSWD=$(dialog --clear --inputbox "Digite a senha de root" 10 25 --stdout)

USER=$(dialog  --clear --inputbox "Digite o nome do novo Usuario" 10 25 --stdout)
USER_PASSWD=$(dialog --clear --inputbox "Digite a senha  de $USER" 10 25 --stdout)


#### configure base system
#### setting hostname
arch_chroot "echo $HNAME > /etc/hostname"
arch_chroot "echo -e '127.0.0.1    localhost.localdomain    localhost'\n'::1        localhost.localdomain    localhost'\n'127.0.1.1    $HNAME.localdomain    $HNAME' >> /etc/hosts"

#### locales setting locale pt_BR.UTF-8 UTF-8
sed 's/^#'$LANGUAGE'/'$LANGUAGE/ /mnt/etc/locale.gen > /tmp/locale && mv /tmp/locale /mnt/etc/locale.gen
arch_chroot "locale-gen"
arch_chroot "echo -e LANG=$LANGUAGE'\n'LC_MESSAGES=$LANGUAGE> /etc/locale.conf"
arch_chroot "export LANG=$LANGUAGE"

#### Vconsole
arch_chroot "echo -e KEYMAP=$KEYBOARD_LAYOUT'\n'FONT=lat0-16'\n'FONT_MAP= > /etc/vconsole.conf"

#### Setting timezone
arch_chroot "ln -s /usr/share/zoneinfo/$ZONE/$SUBZONE /etc/localtime"

#### enable multilib
arch_chroot "sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf"

#### Setting hw CLOCK
arch_chroot "hwclock --systohc --$CLOCK"

#### root password
arch_chroot "echo -e $ROOT_PASSWD'\n'$ROOT_PASSWD | passwd"

#### criar usuario
arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash $USER"

#### Definir senha do usuário 
arch_chroot "echo -e $USER_PASSWD'\n'$USER_PASSWD | passwd `echo $USER`"
arch_chroot "sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers"

#### networkmanager acpi
arch_chroot "systemctl enable NetworkManager.service"
arch_chroot "systemctl enable acpid.service"


#### Driver
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
arch_chroot "pacman -S --noconfirm xf86-input-synaptics synaptics"


dialog --title "INTEFACE GRAFICA" --clear --yesno "Deseja Instalar Windows Manager ?" 9 62
if [[ $? -eq 0 ]]; then
  arch_chroot "pacman -S --noconfirm xorg xorg-xkbcomp xorg-xinit xorg-server xorg-twm xorg-xclock xorg-xinit xorg-drivers xorg-xkill xorg-fonts-100dpi xorg-fonts-75dpi mesa xterm"
  
  desktop=$(dialog --clear --menu "Desktop Environment" 15 30 10  1 "Gnome Minimal" 2 "Gnome" 3 "Plasma kde" 4 "cinnamon" 5 "xfce4" 6 "deepin" 7 "Minimal"  --stdout)
  case $desktop in
      1)
          DEpkg="gdm gnome-shell gnome-backgrounds gnome-control-center gnome-screenshot gnome-system-monitor gnome-terminal gnome-tweak-tool nautilus gedit gvfs gnome-calculator gnome-disk-utility"
          ;;
      2)
          DEpkg="gdm gnome gnome-tweak-tool"
          ;;
      3)
          DEpkg="sddm plasma plasma-wayland-session dolphin konsole kate kcalc ark gwenview spectacle okular packagekit-qt5"
          ;;
      4)
          DEpkg="gdm cinnamon sakura gnome-disk-utility nemo-fileroller mousepad"
          ;;
      5)
          DEpkg="lxdm xfce4 xfce4-goodies network-manager-applet file-roller leafpad"
          ;;
      6)
          DEpkg="sddm deepin deepin-extra ark gnome-disk-utility gedit"
          ;;
  esac

  arch_chroot "pacman -Sy $DEpkg tilix mesa eog xdg-user-dirs-gtk firefox evince adwaita-icon-theme papirus-icon-theme faenza-icon-theme gparted --noconfirm --needed"

  case $desktop in
      1 | 2 | 4)
          arch_chroot "systemctl enable gdm.service"
          ;;
      3 | 6)
          arch_chroot "echo -e '[Theme]\nCurrent=breeze' >> /usr/lib/sddm/sddm.conf.d/default.conf"
          arch-chroot "systemctl enable sddm.service"
          ;; 
      5)
          arch-chroot "systemctl enable lxdm.service"
          ;;
  esac
fi

dialog --clear --title " Installation finished sucessfully " --yesno "\nDo you want to reboot?" 9 62
if [[ $? -eq 0 ]]; then
  echo "System will reboot in a moment..."
  sleep 3
  clear
  umount -R /mnt
  reboot
fi

