#!/bin/bash
# ============================================================
#  Full Openbox Setup for Void Linux (glibc)
#  Faithful, feature-rich rewrite inspired by drewgrif/openbox-setup
#  Maintains the "kitchen sink" spirit: themes, icons, fonts,
#  Openbox stack, zsh/oh-my-zsh/starship, services, wallpapers, etc.
# ============================================================

set -euo pipefail

# ---------- Helpers ----------
die() { echo "ERROR: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

REPO_DIR="${REPO_DIR:-$HOME/openbox-setup}"   # path to the cloned repo
USER_SHELL="${USER_SHELL:-/bin/zsh}"          # default shell to set for user
INSTALL_LIGHTDM="${INSTALL_LIGHTDM:-false}"   # set true to install LightDM
AUTOLOGIN_USER="${AUTOLOGIN_USER:-$USER}"     # user for autologin if enabled
NITROGEN_WALL="${NITROGEN_WALL:-}"           # optional path to a wallpaper

echo "[*] Starting full Openbox setup for Void Linux"
[ -d "$REPO_DIR" ] || echo "[*] Note: REPO_DIR '$REPO_DIR' not found; config copy steps will be skipped if absent."

# ---------- Sanity ----------
if [ "$(id -u)" -eq 0 ]; then
  echo "[*] Running as root. Will proceed, but recommends running as your user with sudo."
fi

# ---------- Update indexes ----------
echo "[1/12] Updating system indexes and packages..."
sudo xbps-install -Sy || sudo xbps-install -S
sudo xbps-install -Su

# ---------- Core X11 + Desktop stack ----------
echo "[2/12] Installing Xorg and Openbox desktop stack..."
sudo xbps-install -S \
  xorg xorg-minimal xinit \
  mesa-dri mesa-vulkan-intel mesa-vulkan-radeon vulkan-loader \
  openbox obconf obmenu-generator \
  picom polybar \
  rofi dunst \
  thunar thunar-archive-plugin thunar-volman gvfs gvfs-mtp gvfs-smb \
  xfce4-appfinder \
  wezterm tilix \
  pavucontrol pipewire wireplumber alsa-utils \
  flameshot redshift \
  nitrogen feh lxappearance \
  neovim geany micro \
  fastfetch neofetch htop fzf ripgrep fd \
  git curl wget unzip tar xz zip \
  python3 pipx \
  papirus-icon-theme \
  imv sxiv \
  xclip xsel \
  network-manager-applet \
  dbus udisks2 udiskie

# Enable runit services needed at login time
echo "[3/12] Enabling runit services..."
for svc in dbus pipewire wireplumber udisksd; do
  [ -e "/etc/sv/$svc" ] && sudo ln -sf "/etc/sv/$svc" /var/service/ || true
done

# ---------- Browsers (you can add more if you want) ----------
echo "[4/12] Installing browsers..."
sudo xbps-install -S firefox-esr qutebrowser

# ---------- Optional: Display Manager (LightDM) ----------
if [ "$INSTALL_LIGHTDM" = "true" ]; then
  echo "[5/12] Installing LightDM + greeter (optional block enabled)..."
  sudo xbps-install -S lightdm lightdm-gtk3-greeter
  [ -e /etc/sv/lightdm ] && sudo ln -sf /etc/sv/lightdm /var/service/ || true

  # Configure LightDM autologin if requested
  if [ -n "$AUTOLOGIN_USER" ]; then
    echo "[*] Configuring LightDM autologin for user: $AUTOLOGIN_USER"
    sudo sed -i \
      -e "s/^#*autologin-user=.*/autologin-user=$AUTOLOGIN_USER/" \
      -e "s/^#*autologin-session=.*/autologin-session=openbox/" \
      /etc/lightdm/lightdm.conf || true
  fi
else
  echo "[*] Skipping LightDM. You can set INSTALL_LIGHTDM=true to enable it."
fi

# ---------- Fonts ----------
echo "[6/12] Installing fonts (system + Nerd Fonts)..."
sudo xbps-install -S font-dejavu font-noto-ttf font-awesome
mkdir -p "$HOME/.local/share/fonts"

# Nerd Fonts set
pushd /tmp >/dev/null
NF_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
declare -a NFONTS=("FiraCode" "JetBrainsMono" "Hack" "Meslo" "CascadiaCode")
for nf in "${NFONTS[@]}"; do
  if [ ! -f "${nf}.zip" ]; then
    echo "  - Downloading ${nf} Nerd Font..."
    wget -q "${NF_URL}/${nf}.zip" -O "${nf}.zip" || true
    unzip -oq "${nf}.zip" -d "$HOME/.local/share/fonts" || true
  fi
done
fc-cache -fv || true
popd >/dev/null

# ---------- Themes, Icons, Cursors ----------
echo "[7/12] Installing GTK themes, icons, cursors..."
mkdir -p "$HOME/.themes" "$HOME/.icons"

# Orchis GTK theme
if [ ! -d "$HOME/.themes/Orchis-theme" ]; then
  git clone https://github.com/vinceliuice/Orchis-theme.git "$HOME/.themes/Orchis-theme"
  "$HOME/.themes/Orchis-theme/install.sh" --theme dark || true
fi

# Colloid icons
if [ ! -d "$HOME/.icons/Colloid-icon-theme" ]; then
  git clone https://github.com/vinceliuice/Colloid-icon-theme.git "$HOME/.icons/Colloid-icon-theme"
  "$HOME/.icons/Colloid-icon-theme/install.sh" || true
fi

# Papirus already installed via repo; add Bibata cursors
if [ ! -d "$HOME/.icons/Bibata-Modern-Ice" ]; then
  pushd /tmp >/dev/null
  wget -q https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz -O Bibata-Modern-Ice.tar.xz || true
  mkdir -p "$HOME/.icons/Bibata-Modern-Ice"
  tar -xJf Bibata-Modern-Ice.tar.xz -C "$HOME/.icons" || true
  popd >/dev/null
fi

# ---------- Zsh, Oh-My-Zsh, Starship ----------
echo "[8/12] Configuring shell: zsh + oh-my-zsh + starship..."
sudo xbps-install -S zsh starship

# oh-my-zsh unattended
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    || true
fi

# zsh plugins: zsh-autosuggestions, zsh-syntax-highlighting
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# zshrc
cat > "$HOME/.zshrc" <<'ZRC'
# --- oh-my-zsh base ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# --- starship ---
eval "$(starship init zsh)"

# --- aliases ---
alias ll='ls -lh'
alias la='ls -lah'
alias v='nvim'
alias grep='grep --color=auto'
alias cat='bat 2>/dev/null || cat'
alias update='sudo xbps-install -Su'

# --- PATH for pipx / local bins ---
export PATH="$HOME/.local/bin:$PATH"

# --- fix key repeats in some terms (optional) ---
export GTK_THEME=Orchis-Dark
ZRC

# change login shell (if running as real user and chsh exists)
if have chsh && [ -w /etc/passwd ]; then
  (chsh -s "$USER_SHELL" "$USER" 2>/dev/null) || true
fi

# ---------- Configs from repo ----------
echo "[9/12] Deploying configs from repository (if available)..."
mkdir -p "$HOME/.config" "$HOME/.config/openbox" "$HOME/.config/polybar" "$HOME/.config/picom"
if [ -d "$REPO_DIR/config" ]; then
  cp -rT "$REPO_DIR/config" "$HOME/.config"
fi
if [ -d "$REPO_DIR/openbox" ]; then
  cp -rT "$REPO_DIR/openbox" "$HOME/.config/openbox"
fi
# Create sensible defaults if missing
if [ ! -f "$HOME/.config/picom/picom.conf" ]; then
  cat > "$HOME/.config/picom/picom.conf" <<'PIC'
backend = "xrender";
vsync = true;
shadow = true;
fading = true;
inactive-opacity = 0.95;
rounded-corners = true;
PIC
fi
if [ ! -f "$HOME/.config/polybar/config.ini" ]; then
  mkdir -p "$HOME/.config/polybar"
  cat > "$HOME/.config/polybar/launch.sh" <<'PB'
#!/bin/sh
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.5; done
polybar main &
PB
  chmod +x "$HOME/.config/polybar/launch.sh"
  cat > "$HOME/.config/polybar/config.ini" <<'PBC'
[bar/main]
width = 100%
height = 28
modules-left = date
modules-right = pulseaudio memory cpu
font-0 = "FiraCode Nerd Font:size=10"
[module/date]
type = internal/date
interval = 1
date = %a %b %d %H:%M
[module/pulseaudio]
type = internal/pulseaudio
[module/memory]
type = internal/memory
[module/cpu]
type = internal/cpu
PBC
fi

# Openbox autostart (ensure picom/polybar/nm-applet etc start)
mkdir -p "$HOME/.config/openbox"
if [ ! -f "$HOME/.config/openbox/autostart" ]; then
  cat > "$HOME/.config/openbox/autostart"
