#!/bin/bash

# Debian Trixie Minimal Desktop Setup Script
# Run as user jwno from /home/jwno/base_deb directory

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as regular user (not root)
if [[ $EUID -eq 0 ]]; then
   error "This script must NOT be run as root. Run as user jwno."
fi

# Check if we're in the correct directory
if [[ "$PWD" != "/home/jwno/base_deb" ]]; then
    error "Script must be run from /home/jwno/base_deb directory"
fi

log "Starting Debian Trixie setup..."

# Update system
log "Updating package lists..."
sudo apt update || error "Failed to update package lists"

log "Upgrading system..."
sudo apt upgrade -y || error "Failed to upgrade system"

# Install essential packages
log "Installing essential packages..."
sudo apt install -y \
    blueman \
    bluez \
    btop \
    build-essential \
    curl \
    fastfetch \
    fbset \
    firefox \
    flatpak \
    fonts-font-awesome \
    fonts-hack \
    fonts-terminus \
    gawk \
    gimp \
    git \
    gnome-software-plugin-flatpak \
    gpg \
    libx11-dev \
    libxft-dev \
    libxinerama-dev \
    lightdm \
    lightdm-gtk-greeter \
    make \
    network-manager \
    nftables \
    pkg-config \
    psmisc \
    python3-pip \
    python3-venv \
    qtile \
    sxiv \
    tlp \
    tlp-rdw \
    unity-greeter \
    vim \
    wget \
    zram-tools || error "Failed to install essential packages"

# Add flathub repository
log "Adding Flathub repository..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || error "Failed to add Flathub repository"

# Install Google Chrome
log "Installing Google Chrome..."
cd /tmp
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - || error "Failed to add Google Chrome signing key"
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list || error "Failed to add Google Chrome repository"
sudo apt update || error "Failed to update package lists after adding Chrome repo"
sudo apt install -y google-chrome-stable || error "Failed to install Google Chrome"

# Install Flatpak applications
log "Installing Flatpak applications..."
flatpak install -y flathub org.flameshot.Flameshot || error "Failed to install Flameshot"
flatpak install -y flathub com.protonvpn.www || error "Failed to install ProtonVPN"

# Build and install ST terminal
log "Building ST terminal..."
cd /tmp
git clone https://git.suckless.org/st || error "Failed to clone ST repository"
cd st

# Download and apply patches
log "Downloading and applying ST patches..."
wget https://st.suckless.org/patches/blinking_cursor/st-blinking_cursor-20230819-3a6d6d7.diff || error "Failed to download blinking cursor patch"
wget https://st.suckless.org/patches/bold-is-not-bright/st-bold-is-not-bright-20190127-3be4cf1.diff || error "Failed to download bold-is-not-bright patch"
wget https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.9.2.diff || error "Failed to download scrollback mouse patch"
wget https://st.suckless.org/patches/scrollback/st-scrollback-0.9.2.diff || error "Failed to download scrollback patch"

patch -p1 < st-blinking_cursor-20230819-3a6d6d7.diff || error "Failed to apply blinking cursor patch"
patch -p1 < st-bold-is-not-bright-20190127-3be4cf1.diff || error "Failed to apply bold-is-not-bright patch"
patch -p1 < st-scrollback-0.9.2.diff || error "Failed to apply scrollback patch"
patch -p1 < st-scrollback-mouse-0.9.2.diff || error "Failed to apply scrollback mouse patch"

make clean install || error "Failed to build and install ST"

# Copy dotfiles and configurations
log "Setting up dotfiles and configurations..."
cd /home/jwno/base_deb

# Copy vim configuration
log "Setting up vim configuration..."
cp vimrc /home/jwno/.vimrc || error "Failed to copy .vimrc"
sudo cp vimrc /root/.vimrc || error "Failed to copy .vimrc to root"

# Copy bash configuration  
log "Setting up bash configuration..."
cp bashrc /home/jwno/.bashrc || error "Failed to copy .bashrc"
sudo cp bashrc /root/.bashrc || error "Failed to copy .bashrc to root"

# Create .config directory if it doesn't exist
mkdir -p /home/jwno/.config

# Copy config directories (rename from repo names to actual names)
log "Setting up application configurations..."
cp -r config/fastfetch /home/jwno/.config/ || error "Failed to copy fastfetch config"
cp -r config/gtk-3.0 /home/jwno/.config/ || error "Failed to copy gtk-3.0 config"
cp -r config/gtk-4.0 /home/jwno/.config/ || error "Failed to copy gtk-4.0 config"
cp -r config/qtile /home/jwno/.config/ || error "Failed to copy qtile config"

# Create directories for themes and icons
mkdir -p /home/jwno/.themes
mkdir -p /home/jwno/.icons

# Copy themes and icons (if directories exist)
if [ -d "themes" ]; then
    log "Setting up themes..."
    cp -r themes/* /home/jwno/.themes/ || error "Failed to copy themes"
fi

if [ -d "icons" ]; then
    log "Setting up icons..."
    cp -r icons/* /home/jwno/.icons/ || error "Failed to copy icons"
fi

# Create Firefox profile directories and copy Chrome configs
mkdir -p /home/jwno/.mozilla/firefox/default.default/chrome
log "Setting up Firefox configuration..."
cp Documents/chrome/userChrome.css /home/jwno/.mozilla/firefox/default.default/chrome/ || error "Failed to copy userChrome.css"
cp Documents/chrome/userContent.css /home/jwno/.mozilla/firefox/default.default/chrome/ || error "Failed to copy userContent.css"

# Copy TLP configuration
log "Setting up TLP configuration..."
sudo cp tlp.conf /etc/tlp.conf || error "Failed to copy TLP configuration"

# Set proper ownership for user files
log "Setting file ownership..."
sudo chown -R jwno:jwno /home/jwno/.config
sudo chown -R jwno:jwno /home/jwno/.themes
sudo chown -R jwno:jwno /home/jwno/.icons
sudo chown -R jwno:jwno /home/jwno/.mozilla
sudo chown jwno:jwno /home/jwno/.vimrc
sudo chown jwno:jwno /home/jwno/.bashrc

# Enable services
log "Enabling services..."
sudo systemctl enable lightdm || error "Failed to enable lightdm"
sudo systemctl enable tlp || error "Failed to enable TLP"
sudo systemctl enable NetworkManager || error "Failed to enable NetworkManager"

# Set LightDM to use unity greeter
log "Configuring LightDM..."
sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=unity-greeter/' /etc/lightdm/lightdm.conf || error "Failed to configure LightDM greeter"

log "Setup completed successfully!"
log "Please reboot to start the graphical environment."
