#!/bin/bash
# JustAGuy Linux - Openbox Setup (Void Linux adaptation)
# Faithful rewrite for Void Linux base install
# Preserves all interactive prompts, optional tools, themes, and configs

set -e

# ---------------------------
# Command line options
# ---------------------------
ONLY_CONFIG=false
EXPORT_PACKAGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --only-config)
            ONLY_CONFIG=true
            shift
            ;;
        --export-packages)
            EXPORT_PACKAGES=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages and external tools)"
            echo "  --export-packages  Export package list for Void Linux"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ---------------------------
# Paths
# ---------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/openbox"
TEMP_DIR="/tmp/openbox_$$"
LOG_FILE="$HOME/openbox-install.log"

# ---------------------------
# Logging and colors
# ---------------------------
exec > >(tee -a "$LOG_FILE") 2>&1
trap "rm -rf $TEMP_DIR" EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
msg() { echo -e "${CYAN}$*${NC}"; }

# ---------------------------
# Package groups
# ---------------------------
PACKAGES_CORE=(
xorg xorg-apps xbacklight xbindkeys xvkbd xinput
    base-devel openbox tint2 xdotool
    libnotify libnotify-devel
    xorgproto libX11-devel libXext-devel libXft-devel libXinerama-devel libXrandr-devel libXrender-devel libXt-devel libXcursor-devel
)

PACKAGES_UI=(
    polybar rofi dunst feh lxappearance network-manager-applet
)

PACKAGES_FILE_MANAGER=(
    Thunar thunar-archive-plugin thunar-volman
    gvfs dialog mtools samba cifs-utils fd unzip
)

PACKAGES_AUDIO=(
    pavucontrol pulsemixer pamixer pipewire
)

PACKAGES_UTILITIES=(
    avahi acpi acpid xfce4-power-manager xfce4-appfinder
    flameshot imv micro xdg-user-dirs-gtk
)

PACKAGES_TERMINAL=(
    eza
)

PACKAGES_FONTS=(
    dejavu-fonts-ttf liberation-fonts-ttf font-awesome6 google-fonts-ttf nerd-fonts noto-fonts-ttf noto-fonts-cjk noto-fonts-ttf-extra noto-fonts-emoji terminus-font
)

PACKAGES_BUILD=(
    cmake meson ninja curl pkg-config
)

PACKAGES_OBMENU=(
    perl-Gtk3 perl-Module-Build cpanminus make
)

EXTRA_PACKAGES=(
    firefox-esr firefox eza imv
)

# ---------------------------
# Export package list
# ---------------------------
export_packages() {
    echo "=== Openbox Setup - Void Linux Package List ==="
    local all_packages=(
        "${PACKAGES_CORE[@]}"
        "${PACKAGES_UI[@]}"
        "${PACKAGES_FILE_MANAGER[@]}"
        "${PACKAGES_AUDIO[@]}"
        "${PACKAGES_UTILITIES[@]}"
        "${PACKAGES_TERMINAL[@]}"
        "${PACKAGES_FONTS[@]}"
        "${PACKAGES_BUILD[@]}"
        "${PACKAGES_OBMENU[@]}"
        "${EXTRA_PACKAGES[@]}"
    )
    echo
    echo "Run the following command to install all packages on Void Linux:"
    echo
    echo "sudo xbps-install -Sy ${all_packages[*]}"
    echo
}

if [ "$EXPORT_PACKAGES" = true ]; then
    export_packages
    exit 0
fi

# ---------------------------
# Banner
# ---------------------------
clear
echo -e "${CYAN}"
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |j|u|s|t|a|g|u|y|l|i|n|u|x| "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |o|p|e|n|b|o|x| |s|e|t|u|p| "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo -e "${NC}\n"

read -p "Install Openbox? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# ---------------------------
# System update and install
# ---------------------------
if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo xbps-install -Syu

    msg "Installing core packages..."
    sudo xbps-install -Sy "${PACKAGES_CORE[@]}"

    msg "Installing UI components..."
    sudo xbps-install -Sy "${PACKAGES_UI[@]}"

    msg "Installing file manager..."
    sudo xbps-install -Sy "${PACKAGES_FILE_MANAGER[@]}"

    msg "Installing audio support..."
    sudo xbps-install -Sy "${PACKAGES_AUDIO[@]}"

    msg "Installing utilities..."
    sudo xbps-install -Sy "${PACKAGES_UTILITIES[@]}"

    msg "Installing terminal tools..."
    sudo xbps-install -Sy "${PACKAGES_TERMINAL[@]}"

    msg "Installing fonts..."
    sudo xbps-install -Sy "${PACKAGES_FONTS[@]}"

    msg "Installing build tools..."
    sudo xbps-install -Sy "${PACKAGES_BUILD[@]}"

    msg "Installing obmenu-generator dependencies..."
    sudo xbps-install -Sy "${PACKAGES_OBMENU[@]}"
    cpanm File::DesktopEntry || msg "Installed libfile-desktopentry-perl via cpan"

    msg "Installing extra packages (browsers, etc.)..."
    sudo xbps-install -Sy "${EXTRA_PACKAGES[@]}"

    # Enable services via runit
    ln -sf /etc/sv/avahi /var/service/
    ln -sf /etc/sv/acpid /var/service/
else
    msg "Skipping package installation (--only-config mode)"
fi

# ---------------------------
# Setup directories
# ---------------------------
xdg-user-dirs-update
mkdir -p ~/Screenshots

# ---------------------------
# Handle existing config
# ---------------------------
if [ -d "$CONFIG_DIR" ]; then
    clear
    read -p "Found existing openbox config. Backup? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "$CONFIG_DIR" "$CONFIG_DIR.bak.$(date +%s)"
        msg "Backed up existing config"
    else
        clear
        read -p "Overwrite without backup? (y/n) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || die "Installation cancelled"
        rm -rf "$CONFIG_DIR"
    fi
fi

# ---------------------------
# Copy configs
# ---------------------------
msg "Setting up configuration..."
mkdir -p "$CONFIG_DIR"
if [ -d "$SCRIPT_DIR/config" ]; then
    cp -a "$SCRIPT_DIR/config/." "$CONFIG_DIR/" || die "Failed to copy openbox configuration"
    if [ -f "$CONFIG_DIR/menu.xml" ]; then
        sed -i "s|USER_HOME_DIR|$HOME|g" "$CONFIG_DIR/menu.xml"
        msg "Updated menu.xml with user-specific paths"
    fi
else
    die "config directory not found"
fi

# ---------------------------
# Install Openbox theme
# ---------------------------
if [ "$ONLY_CONFIG" = false ]; then
    msg "Installing custom Openbox theme..."
    mkdir -p ~/.themes
    if [ -d "$SCRIPT_DIR/config/themes/Simply_Circles_Dark" ]; then
        cp -r "$SCRIPT_DIR/config/themes/Simply_Circles_Dark" ~/.themes/
    fi
fi

# ---------------------------
# Install obmenu-generator
# ---------------------------
if [ "$ONLY_CONFIG" = false ]; then
    msg "Installing obmenu-generator..."
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    git clone https://github.com/trizen/Linux-DesktopFiles.git || die "Failed to clone Linux-DesktopFiles"
    cd Linux-DesktopFiles
    perl Build.PL || die "Failed to configure Linux-DesktopFiles"
    ./Build || die "Failed to build Linux-DesktopFiles"
    ./Build test || msg "Warning: Tests failed but continuing..."
    sudo ./Build install || die "Failed to install Linux-DesktopFiles"
    cd "$TEMP_DIR"

    mkdir -p ~/.local/bin/
    mkdir -p ~/.config/obmenu-generator
    git clone https://github.com/trizen/obmenu-generator.git
    cp obmenu-generator/obmenu-generator ~/.local/bin/
    if [ -f "$CONFIG_DIR/obmenu/schema.pl" ]; then
        cp "$CONFIG_DIR/obmenu/schema.pl" ~/.config/obmenu-generator/
    fi

    export PATH="$HOME/.local/bin:$PATH"
    if [ -n "$DISPLAY" ]; then
        obmenu-generator -p -i || msg "Warning: Menu generation failed, will retry on first login"
    else
        msg "No X display found
