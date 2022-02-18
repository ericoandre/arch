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


### wine

```bash
sudo pacman -S --noconfirm wine wine-mono wine-gecko winetricks
```


### Yay

```bash
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
cd ~ && rm -rf yay
```

### gnome-extension

```bash
yay -S --noconfirm --needed  chrome-gnome-shell gnome-shell-extension-dash-to-dock 
```

