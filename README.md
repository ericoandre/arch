# Arch Linux



### Visual Code Studio

```bash
wget "https://go.microsoft.com/fwlink/?LinkID=620885" -O vscode.tar.gz
tar -vzxf vscode.tar.gz -C /opt/
ln -sf /mnt/opt/VSCode-linux-x64/code /usr/bin/code
echo -e '[Desktop Entry]\nVersion=1.0\nName=vscode\nExec=code\nIcon=/opt/VSCode-linux-x64/resources/app/resources/linux/code.png\nType=Application\nCategories=Development;Application' | tee /usr/share/applications/vscode.desktop
```


### Grub Theme

```bash
mkdir -p "/boot/grub/themes/CyberRe"
cp -a arch/CyberRe /boot/grub/themes/CyberRe
cp -an /etc/default/grub /etc/default/grub.bak

grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"/boot/grub/themes/CyberRe/theme.txt\"" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
```

### Yay
```bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd /tmp/yay && makepkg -si --noconfirm
cd .. && rm -rf /tmp/yay
```


### powerlevel10k

```bash
yay -S --noconfirm --needed nerd-fonts-fira-code nordic-darker-standard-buttons-theme nordic-darker-theme nordic-theme
yay -S --noconfirm --needed gnome-shell-extension-dash-to-dock 

cd ~
touch "~/.cache/zshhistory"
mv arch/zsh ~/.zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
ln -s "~/zsh/zshrc" ~/.zshrc
```
