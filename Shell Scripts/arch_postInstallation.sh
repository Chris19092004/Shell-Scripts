#!/bin/bash
set -euo pipefail

TARGET_USER="chris"

echo "Criando usuário..."
useradd -m -G wheel -s /bin/bash "$TARGET_USER"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
passwd "$TARGET_USER"

# Temporary passwordless sudo so makepkg and yay don't hang asking for a password
echo "$TARGET_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-temp-installer

# Packes installation - Pacman
sudo pacman -S --needed --noconfirm base-devel bashtop clang cmake curl distrobox docker docker-buildx docker-compose dotnet-sdk flatpak gdb git jdk-openjdk kitty lazydocker lazygit libreoffice-fresh mariadb maven ncdu neovim ninja nodejs npm otf-monaspace-nerd plasma-desktop plasma-nm plasma-pa python python-pip python-pipx qutebrowser ranger rofi sddm sddm-kcm swaybg tmux tree-sitter-cli ufw waybar zsh

echo "Configurando Snapper e snapshots Btrfs..."

# 1. Unmount your existing @.snapshots subvolume if mounted
if mountpoint -q /.snapshots; then
    umount /.snapshots
fi
rm -rf /.snapshots

# 2. Create Snapper config (this creates a new nested /.snapshots subvolume)
snapper -c root create-config /

# 3. Delete Snapper's nested subvolume and remount your @.snapshots subvolume
btrfs subvolume delete /.snapshots
mkdir -p /.snapshots
mount -a

# 4. Set permissions so your wheel user can inspect snapshots without sudo
chmod 750 /.snapshots
chown :wheel /.snapshots

# 5. Set retention limits and allow wheel group access
snapper -c root set-config \
    "ALLOW_GROUPS=wheel" \
    "SYNC_ACL=yes" \
    "TIMELINE_LIMIT_HOURLY=5" \
    "TIMELINE_LIMIT_DAILY=7" \
    "TIMELINE_LIMIT_WEEKLY=0" \
    "TIMELINE_LIMIT_MONTHLY=0" \
    "TIMELINE_LIMIT_YEARLY=0"

# 6. Enable automatic timeline and cleanup timers
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

# Enable AUR and yay
echo "Instalando yay..."

su - "$TARGET_USER" -c '
    git clone https://aur.archlinux.org/yay.git /tmp/yay &&
    cd /tmp/yay &&
    makepkg -si --noconfirm
'

rm -rf /tmp/yay

# Enable and configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw

# Enable docker
systemctl enable --now docker.service
usermod -aG docker "$TARGET_USER"

# Lazyvim
echo "Instalando LazyVim..."
su - "$TARGET_USER" -c '
    mkdir -p ~/.config &&
    git clone https://github.com/LazyVim/starter ~/.config/nvim &&
    rm -rf ~/.config/nvim/.git
'

echo "Instalando Nix..."
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon --no-confirm

echo "Instalando pacotes AUR..."
su - "$TARGET_USER" -c "yay -S --noconfirm swayfx swaylock-effects waypaper"

# Remove temporary passwordless sudo rule
rm -f /etc/sudoers.d/99-temp-installer

echo "Habilitando SDDM..."
systemctl enable sddm

echo "Concluído! Reinicie o sistema com 'reboot' para iniciar o SDDM."
