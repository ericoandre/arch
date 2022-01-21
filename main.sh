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

EXTRA_PKGS="go wget cmatrix gcc  make jre8-openjdk jre8-openjdk-headless openbsd-netcat traceroute git ntfs-3g os-prober grub virtualbox-guest-utils acpi acpid dbus unrar p7zip tar rsync ufw exfat-utils networkmanager iw net-tools dhclient dhcpcd neofetch nano alsa-plugins alsa-utils alsa-firmware pulseaudio pulseaudio-alsa pavucontrol volumeicon bash-completion zsh zsh-syntax-highlighting zsh-autosuggestions"

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
  sed -i 's/^#Color/Color\nILoveCandy' /etc/pacman.conf
  if [ "$(uname -m)" = "x86_64" ]; then
    sed -i '/multilib\]/,+1 s/^#//' /etc/pacman.conf
  fi
  pacman -Sy
}

inst_base(){
  # pacstrap /mnt base bash nano vim-minimal vi linux-firmware cryptsetup e2fsprogs findutils gawk inetutils iproute2 jfsutils licenses linux-firmware logrotate lvm2 man-db man-pages mdadm pciutils procps-ng reiserfsprogs sysfsutils xfsprogs usbutils `echo $kernel`
  pacstrap /mnt base base-devel linux linux-headers linux-firmware ttf-liberation ttf-dejavu ttf-hack ttf-roboto `echo $EXTRA_PKGS`
  cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
  genfstab -U -p /mnt >> /mnt/etc/fstab
  echo "/opt/swap/swapfile             none    swap    sw        0       0" >> /mnt/etc/fstab
  arch_chroot "systemctl enable NetworkManager acpid && mkinitcpio -p linux"

}

inst_boot_load(){
    proc=$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')
    if [ "$proc" = "GenuineIntel" ]; then
        pacstrap /mnt intel-ucode
    elif [ "$proc" = "AuthenticAMD" ]; then
        pacstrap /mnt amd-ucode
    fi

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

echo -ne "
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------
"

pacman -Syy && pacman -S --noconfirm dialog terminus-font reflector

timedatectl set-ntp true
loadkeys br-abnt2
setfont ter-v22b

echo -ne "
-------------------------------------------------------------------------
                    Formating Disk
-------------------------------------------------------------------------
"

#### Particionamento
particionar_discos
monta_particoes

#### Configuracao e Instalcao
conf_repositorio


echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
inst_base

echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
inst_boot_load

echo -ne "
-------------------------------------------------------------------------
                              Configuracao 
-------------------------------------------------------------------------
"
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

#### setting hostname
arch_chroot "echo $HNAME > /etc/hostname"
arch_chroot "echo -e '127.0.0.1    localhost.localdomain    localhost\n::1        localhost.localdomain    localhost\n127.0.1.1    $HNAME.localdomain    $HNAME' >> /etc/hosts"

#setting locale pt_BR.UTF-8 UTF-8
sed 's/^#'$LANGUAGE'/'$LANGUAGE/ /mnt/etc/locale.gen > /tmp/locale && mv /tmp/locale /mnt/etc/locale.gen
arch_chroot "echo -e LANG=$LANGUAGE'\n'LC_MESSAGES=$LANGUAGE> /etc/locale.conf"
arch_chroot "locale-gen"
arch_chroot "export LANG=$LANGUAGE"

#### Vconsole
arch_chroot "echo -e KEYMAP=$KEYBOARD_LAYOUT'\n'FONT=lat0-16'\n'FONT_MAP= > /etc/vconsole.conf"

#### Setting timezone
arch_chroot "ln -s /usr/share/zoneinfo/$ZONE/$SUBZONE /etc/localtime"

#### Setting hw CLOCK
arch_chroot "hwclock --systohc --$CLOCK"

#### root password
arch_chroot "echo -e $ROOT_PASSWD'\n'$ROOT_PASSWD | passwd"

#### criar usuario
arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash $USER"

#### Definir senha do usuário 
arch_chroot "echo -e $USER_PASSWD'\n'$USER_PASSWD | passwd `echo $USER`"

arch_chroot "echo %wheel ALL=(ALL) ALL >> /etc/sudoers"

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

arch_chroot "pacman -S --noconfirm xf86-input-synaptics"


dialog --title "INTEFACE GRAFICA" --clear --yesno "Deseja Instalar Windows Manager ?" 10 30
if [[ $? -eq 0 ]]; then
  arch_chroot "pacman -S --noconfirm xorg xorg-xinit xorg-server xorg-twm xorg-xclock xorg-xinit xorg-drivers xorg-xkill xorg-fonts-100dpi xorg-fonts-75dpi mesa xterm"
  
  DM=$(dialog  --clear --menu "Selecione Gerenociador grafico" 15 30 4  1 "gnome" 2 "cinnamon" 3 "plasma" 4 "mate" 5 "Xfce" 6 "deepin" 7 "i3" --stdout)
  if [[ $DM -eq 1 ]]; then
    #arch_chroot "pacman -S --noconfirm gnome gnome-tweaks file-roller gdm"
    arch_chroot "pacman -S --noconfirm gdm gnome-shell gnome-backgrounds gnome-control-center gnome-screenshot gnome-system-monitor gnome-terminal gnome-tweak-tool nautilus gedit gnome-calculator gnome-disk-utility"
    arch_chroot "systemctl enable gdm.service"
  elif [[ $DM -eq 2 ]]; then
    arch_chroot "pacman -S --noconfirm cinnamon sakura gnome-disk-utility nemo-fileroller gdm"
    arch_chroot "systemctl enable gdm.service"
  elif [[ $DM -eq 3 ]]; then
    arch_chroot "pacman -S --noconfirm plasma file-roller sddm"
    arch_chroot "echo -e '[Theme]\nCurrent=breeze' >> /usr/lib/sddm/sddm.conf.d/default.conf"
    arch_chroot "systemctl enable sddm.service"
  elif [[ $DM -eq 4 ]]; then
    arch_chroot "pacman -S --noconfirm mate mate-extra gnome-disk-utility lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
    arch_chroot "systemctl enable lightdm.service"
  elif [[ $DM -eq 5 ]]; then
    arch_chroot "pacman -S --noconfirm xfce4 xfce4-goodies file-roller network-manager-applet lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
    arch_chroot "systemctl enable lightdm.service"
  elif [[ $DM -eq 6 ]]; then
    arch_chroot "pacman -S --noconfirm deepin deepin-extra ark gnome-disk-utility sddm"
    arch_chroot "echo -e '[Theme]\nCurrent=breeze' >> /usr/lib/sddm/sddm.conf.d/default.conf"
    arch_chroot "systemctl enable sddm.service"
  elif [[ $DM -eq 7 ]]; then
    arch_chroot "pacmanpacman -S --noconfirm --needed --asdeps lightdm lightdm-gtk-greeter i3 feh gnome-disk-utility lightdm-gtk-greeter-settings"
    arch_chroot "systemctl enable lightdm.service"
  fi
  arch_chroot "pacman -S --noconfirm ntp vlc gparted papirus-icon-theme faenza-icon-theme tilix eog xdg-user-dirs-gtk firefox evince mousepad"
fi




# echo -ne "
# -------------------------------------------------------------------------
#                     Installing Base System  
# -------------------------------------------------------------------------
# "
# cat /root/ArchTitus/pkg-files/pacman-pkgs.txt | while read line 
# do
#     echo "INSTALLING: ${line}"
#    sudo pacman -S --noconfirm --needed ${line}
# done


#   cd ~
#   git clone https://aur.archlinux.org/yay.git /mnt/home/$USER/yay
#   cd ~/yay && makepkg -si --noconfirm

####### aur-pkgs
# ttf-meslo
# nerd-fonts-fira-code
# nordic-darker-standard-buttons-theme
# nordic-darker-theme
# nordic-kde-git
# nordic-theme

# ttf-meslo-nerd-font-powerlevel10k

# chsh -s /bin/zsh
# yay -S oh-my-zsh-git
# cp /usr/share/oh-my-zsh/zshrc ~/.zshrc


# cd ~
# touch "~/.cache/zshhistory"
# git clone "https://github.com/ChrisTitusTech/zsh"
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
# ln -s "~/zsh/.zshrc" ~/.zshrc

# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# mkdir -p "/boot/grub/themes/CyberRe"
# cp -a CyberRe /boot/grub/themes/CyberRe
# cp -an /etc/default/grub /etc/default/grub.bak

# grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
# echo "GRUB_THEME=\"/boot/grub/themes/CyberRe/theme.txt\"" >> /etc/default/grub
# grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt
poweroff
