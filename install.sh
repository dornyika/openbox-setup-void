#!/bin/bash
# --------------------------------------------------
#  Openbox Setup Script for Void Linux
#  Adapted from drewgrif/openbox-setup (Debian-based) by ChatGPT
# --------------------------------------------------

set -e

echo "[*] Updating system..."
sudo xbps-install -Su

# --------------------------------------------------
# Essential system + desktop packages
# --------------------------------------------------
echo "[*] Installing core desktop environment..."
sudo xbps-install -S \
  xorg xorg-minimal xinit \
  openbox obconf obmenu-generator \
  picom polybar \
  thunar xfce4-appfinder \
  firefox-esr geany \
  dunst rofi \
  pipewire wireplumber alsa-utils \
  flameshot redshift \
  wezterm tilix \
  micro fzf fastfetch \
  feh lxappearance \
  sxiv papirus-icon-theme \
  git curl wget unzip \
  zsh starship \
  neofetch htop pavucontrol \
  gvfs gvfs-smb gvfs-mtp

# --------------------------------------------------
# Fonts
# --------------------------------------------------
echo "[*] Installing fonts..."
sudo xbps-install -S font-dejavu font-noto-ttf font-awesome
mkdir -p ~/.local/share/fonts

# Nerd Fonts (FiraCode as example)
cd /tmp
if [ ! -f "FiraCode.zip" ]; then
  wget -O FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  unzip -o FiraCode.zip -d ~/.local/share/fonts
fi
fc-cache -fv

# --------------------------------------------------
# Themes & Icons
# --------------------------------------------------
echo "[*] Installing Orchis and Colloid themes..."
mkdir -p ~/.themes ~/.icons

# Orchis GTK theme
if [ ! -d ~/.themes/Orchis-theme ]; then
  git clone https://github.com/vinceliuice/Orchis-theme.git ~/.themes/Orchis-theme
  ~/.themes/Orchis-theme/install.sh --theme dark
fi

# Colloid icon theme
if [ ! -d ~/.icons/Colloid-icon-theme ]; then
  git clone https://github.com/vinceliuice/Colloid-icon-theme.git ~/.icons/Colloid-icon-theme
  ~/.icons/Colloid-icon-theme/install.sh
fi

# --------------------------------------------------
# ZSH + Oh My Zsh + Starship
# --------------------------------------------------
echo "[*] Setting up zsh environment..."
if [ ! -d ~/.oh-my-zsh ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Starship prompt
if ! command -v starship >/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Custom zshrc
cat > ~/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git fzf)
source $ZSH/oh-my-zsh.sh
eval "$(starship init zsh)"
EOF

chsh -s /bin/zsh

# --------------------------------------------------
# Config Files
# --------------------------------------------------
echo "[*] Copying configs..."
cd ~/openbox-setup

mkdir -p ~/.config
cp -r config/* ~/.config/

mkdir -p ~/.config/openbox
cp -r openbox/* ~/.config/openbox/

# --------------------------------------------------
# Wallpapers
# --------------------------------------------------
mkdir -p ~/Pictures/wallpapers
cp -r wallpapers/* ~/Pictures/wallpapers/

# --------------------------------------------------
# Runit services
# --------------------------------------------------
echo "[*] Enabling services (runit)..."
sudo ln -sf /etc/sv/dbus /var/service/
sudo ln -sf /etc/sv/pipewire /var/service/
sudo ln -sf /etc/sv/wireplumber /var/service/

# --------------------------------------------------
# X init
# --------------------------------------------------
echo "[*] Creating ~/.xinitrc..."
cat > ~/.xinitrc <<EOF
#!/bin/sh
exec openbox-session
EOF
chmod +x ~/.xinitrc

# --------------------------------------------------
# Done
# --------------------------------------------------
echo "[*] Installation complete!"
echo "Reboot, log in, and run 'startx' to enter your new Openbox desktop."
