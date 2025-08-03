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

section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

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
section "SYSTEM UPDATE"
log "Updating package lists..."
sudo apt update || error "Failed to update package lists"

log "Upgrading system..."
sudo apt upgrade -y || error "Failed to upgrade system"

# Install essential packages
section "PACKAGE INSTALLATION"
log "Installing essential packages..."
sudo apt install -y \
    blueman \
    bluez \
    brightnessctl \
    btop \
    build-essential \
    cliphist \
    curl \
    dunst \
    fastfetch \
    fbset \
    firefox-esr-l10n-en-ca \
    flatpak \
    fonts-font-awesome \
    fonts-hack \
    fonts-terminus \
    gawk \
    gimp \
    git \
    libx11-dev \
    libxft-dev \
    libxinerama-dev \
    lightdm \
    lightdm-gtk-greeter \
    make \
    network-manager \
    nftables \
    picom \
    pkg-config \
    psmisc \
    pulseaudio \
    python3-pip \
    python3-venv \
    qtile \
    sxiv \
    tlp \
    tlp-rdw \
    vim \
    wget \
    xclip \
    zram-tools || error "Failed to install essential packages"

# Install Python packages
section "PYTHON PACKAGES"
log "Creating Python virtual environment..."
python3 -m venv /home/jwno/.local/venv || error "Failed to create virtual environment"

log "Installing Python packages in virtual environment..."
source /home/jwno/.local/venv/bin/activate || error "Failed to activate virtual environment"
pip install pulsectl-asyncio || error "Failed to install pulsectl-asyncio"
deactivate

# Add flathub repository
section "FLATPAK SETUP"
log "Adding Flathub repository..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || error "Failed to add Flathub repository"

# Install Flatpak applications
log "Installing Flatpak applications..."
flatpak install -y flathub org.flameshot.Flameshot || error "Failed to install Flameshot"
flatpak install -y flathub com.protonvpn.www || error "Failed to install ProtonVPN"

# Build and install ST terminal
section "SUCKLESS TERMINAL BUILD"
log "Building ST terminal..."
mkdir -p /home/jwno/src
cd /home/jwno/src
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

sudo make clean install || error "Failed to build and install ST"

# Install ble.sh
section "BLE.SH INSTALLATION"
log "Installing ble.sh..."
cd /home/jwno/src
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git || error "Failed to clone ble.sh repository"
cd ble.sh
sudo make install PREFIX=/usr/local || error "Failed to build and install ble.sh"
cd /home/jwno/base_deb

# Copy dotfiles and configurations
section "DOTFILES CONFIGURATION"
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
cp -r Documents/qtile /home/jwno/.config/ || error "Failed to copy qtile config"

# Install themes and icons system-wide
section "THEMES AND ICONS"
log "Installing themes system-wide..."
cd themes
tar -xf Tokyonight-Dark.tar.xz || error "Failed to extract Tokyonight-Dark theme"
sudo cp -r Tokyonight-Dark /usr/share/themes/ || error "Failed to install Tokyonight-Dark theme"

log "Installing icons system-wide..."
cd ../icons
tar -xf BreezeX-RosePine-Linux.tar.xz || error "Failed to extract BreezeX-RosePine-Linux icons"
sudo cp -r BreezeX-RosePine-Linux /usr/share/icons/ || error "Failed to install BreezeX-RosePine-Linux icons"

cd /home/jwno/base_deb

# Copy Documents directory
log "Setting up Documents directory..."
cp -r Documents /home/jwno/ || error "Failed to copy Documents directory"

# Copy Pictures directory
log "Setting up Pictures directory..."
cp -r Pictures /home/jwno/ || error "Failed to copy Pictures directory"

# Copy TLP configuration
log "Setting up TLP configuration..."
sudo cp tlp.conf /etc/tlp.conf || error "Failed to copy TLP configuration"

# Set proper ownership for user files
section "FILE OWNERSHIP"
log "Setting file ownership..."
sudo chown -R jwno:jwno /home/jwno/.config
sudo chown -R jwno:jwno /home/jwno/Documents
sudo chown -R jwno:jwno /home/jwno/Pictures
sudo chown jwno:jwno /home/jwno/.vimrc
sudo chown jwno:jwno /home/jwno/.bashrc

# Enable services
section "SERVICE CONFIGURATION"
log "Enabling services..."
sudo systemctl enable bluetooth || error "Failed to enable Bluetooth"
sudo systemctl enable lightdm || error "Failed to enable lightdm"
sudo systemctl enable tlp || error "Failed to enable TLP"
sudo systemctl enable NetworkManager || error "Failed to enable NetworkManager"
sudo systemctl enable nftables || error "Failed to enable nftables"

# Configure network and firewall
section "NETWORK AND FIREWALL SETUP"
log "Configuring NetworkManager..."
sudo sed -i 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf || error "Failed to configure NetworkManager"

log "Setting up network interfaces..."
sudo tee /etc/network/interfaces >/dev/null <<EOF || error "Failed to setup network interfaces"
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
EOF

log "Setting up firewall rules..."
sudo tee /etc/nftables.conf >/dev/null <<EOF || error "Failed to setup nftables configuration"
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
    chain input { type filter hook input priority filter; policy drop;
        iif "lo" accept
        ct state established,related accept
        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept
        udp sport {53,67,123} accept
        tcp sport 53 accept
        udp sport 67 udp dport 68 accept
    }
    chain forward { type filter hook forward priority filter; policy drop; }
    chain output { type filter hook output priority filter; policy accept; }
}
EOF

log "Applying firewall rules..."
sudo nft -f /etc/nftables.conf || error "Failed to apply nftables rules"

log "Removing default motd..."
sudo rm -f /etc/motd || warn "Failed to remove motd"

log "Setup completed successfully!"

# Clean up copied files from base_deb directory
section "CLEANUP"
log "Cleaning up source files..."
rm -f vimrc || warn "Failed to remove vimrc"
rm -f bashrc || warn "Failed to remove bashrc"
rm -f tlp.conf || warn "Failed to remove tlp.conf"
rm -rf Documents || warn "Failed to remove Documents directory"
rm -rf Pictures || warn "Failed to remove Pictures directory"
rm -rf themes || warn "Failed to remove themes directory"
rm -rf icons || warn "Failed to remove icons directory"
rm -rf config || warn "Failed to remove config directory"

log "Cleanup completed!"

# Replace GRUB with systemd-boot
section "BOOTLOADER CONFIGURATION"
log "Installing systemd-boot..."
sudo apt install -y systemd-boot || error "Failed to install systemd-boot"
sudo bootctl install || error "Failed to install systemd-boot bootloader"

log "Removing GRUB..."
sudo apt purge --allow-remove-essential -y grub* shim-signed ifupdown nano os-prober vim-tiny zutty || error "Failed to remove GRUB packages"
sudo apt autoremove --purge -y || error "Failed to autoremove packages"

log "Current EFI boot entries:"
sudo efibootmgr
echo "Enter GRUB boot ID to delete (check efibootmgr output above):"
read -r BOOT_ID
sudo efibootmgr -b "$BOOT_ID" -B || error "Failed to delete GRUB boot entry"

log "Please reboot to start the graphical environment."
