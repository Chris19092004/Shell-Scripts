#!/bin/bash
set -euo pipefail

# Cria usuário comum e concede permissões de root com sudo para ele
TARGET_USER="chris"

echo "Criando usuário..."
useradd -m -G wheel -s /bin/bash "$TARGET_USER"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
passwd "$TARGET_USER"

# Garante que a regra temporária seguinte seja removida mesmo se o script falhar
trap 'rm -f /etc/sudoers.d/99-temp-installer' EXIT

# Temporariamente elimina a necessidade de senha (necessário para que o script não pare com makepkg e yay peçam senha)
echo "$TARGET_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-temp-installer

# Instalação de pacotes com o Pacman, ignorando o que já estiver atualizado e ignorando necessidade de senha
sudo pacman -S --needed --noconfirm 7zip base-devel btop clang cmake curl dbeaver distrobox docker docker-buildx docker-compose dolphin dotnet-sdk dux-shell emacs eza fastfetch feh flameshot flatpak gamemode gcc gimp git github-cli grim jdk-openjdk kdenlive kitty lazydocker lazygit libreoffice-fresh ly mariadb maven mc mesa ncdu neovim ninja noctalia nodejs nerd-fonts npm obs-studio pipewire pipewire-alsa pipewire-jack pipewire-pulse plasma-desktop python python-adblock python-pip python-pipx retroarch shellcheck slurp tmux tree-sitter-cli ufw virtualbox virtualbox-host-dkms vivaldi wine wireplumber wl-clipboard xdg-desktop-portal-hyprland xdg-user-dirs yazi zsh

echo "Configurando Snapper e snapshots Btrfs..."

# Desmonta subvolume @.snapshots existente se estiver montado
if mountpoint -q /.snapshots; then
    umount /.snapshots
fi
rm -rf /.snapshots

# Cria configuração do Snapper (para permitir rollbacks)
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir -p /.snapshots
mount -a

# Define permissões para gerenciamento de snapshots
chmod 750 /.snapshots
chown :wheel /.snapshots

snapper -c root set-config \
    "ALLOW_GROUPS=wheel" \
    "SYNC_ACL=yes" \
    "TIMELINE_LIMIT_HOURLY=5" \
    "TIMELINE_LIMIT_DAILY=7" \
    "TIMELINE_LIMIT_WEEKLY=0" \
    "TIMELINE_LIMIT_MONTHLY=0" \
    "TIMELINE_LIMIT_YEARLY=0"

# Habilita serviços essenciais para o Snapper e rollbacks funcionarem
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable grub-btrfsd

# Habilita AUR (Arch User Repository) e Yay (um AUR Helper para facilitar instalação de pacotes)
echo "Instalando yay..."

su - "$TARGET_USER" -c '
    git clone https://aur.archlinux.org/yay.git /tmp/yay &&
    cd /tmp/yay &&
    makepkg -si --noconfirm
'

rm -rf /tmp/yay

# Habilita e configura firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw

# Habilita MariaDB
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl start mariadb.service
sudo systemctl enable mariadb.service

# Habilita Docker e coloca o usuário com permissões de root para administrá-lo
systemctl enable docker.service
usermod -aG docker "$TARGET_USER"

# Transforma o Neovim em uma IDE (Lazyvim)
echo "Instalando LazyVim..."
su - "$TARGET_USER" -c '
    mkdir -p ~/.config &&
    git clone https://github.com/LazyVim/starter ~/.config/nvim &&
    rm -rf ~/.config/nvim/.git
'

# Instala o gerenciador de pacotes Nix
echo "Instalando Nix..."
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon

# Instala pacotes AUR
echo "Instalando pacotes AUR..."
su - "$TARGET_USER" -c "yay -S --noconfirm bat-cat-git oh-my-bash-git oh-my-zsh-git mpvpaper visual-studio-code-bin wget2"

# Instalar pacotes Flatpak
flatpak install -y flathub com.valvesoftware.Steam net.davidotek.pupgui2 org.openmw.OpenMW net.pcsx2.PCSX2 org.DolphinEmu.dolphin-emu app.xemu.xemu app.zen_browser.zen

# Cria pastas na home
su "$TARGET_USER" -c "xdg-user-dirs-update"

# Habilitando Gerenciador de Login
systemctl enable ly@tty2.service

# Remove a regra temporária que ignora necessidade de senha
rm -f /etc/sudoers.d/99-temp-installer

# Conclusão do Script
echo "Concluído! Reinicie o sistema com 'reboot' para iniciar o SDDM."
