#!/bin/bash
set -euo pipefail

DISK="${1:-/dev/sda}"

if [[ "$DISK" =~ [0-9]$ ]]; then
	PART_PREFIX="${DISK}p"
else
	PART_PREFIX="$DISK"
fi

# Create partitions (boot, swap and root in btrfs)
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"

sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI" "$DISK"
sgdisk -n 2:0:+4G -t 2:8200 -c 2:"SWAP" "$DISK"
sgdisk -n 3:0:0 -t 3:8300 -c 3:"ROOT" "$DISK"

partprobe "$DISK"
sleep 1

# Format the partitions
mkfs.fat -F 32 "${PART_PREFIX}1"
mkswap "${PART_PREFIX}2"
mkfs.btrfs -f -L archbtrfs "${PART_PREFIX}3"

# Subvolumes for btrfs
mount "${PART_PREFIX}3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@.snapshots
umount /mnt

mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${PART_PREFIX}3" /mnt
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,.snapshots}
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${PART_PREFIX}3" /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var_log "${PART_PREFIX}3" /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,subvol=@pkg "${PART_PREFIX}3" /mnt/var/cache/pacman/pkg
mount -o noatime,compress=zstd,space_cache=v2,subvol=@.snapshots "${PART_PREFIX}3" /mnt/.snapshots

# Mount the file systems
mount --mkdir "${PART_PREFIX}1" /mnt/boot
swapon "${PART_PREFIX}2"

# Install the most basic packages
pacstrap -K /mnt base linux linux-firmware sudo networkmanager grub efibootmgr btrfs-progs snap-pac grub-btrfs snapper inotify-tools nano vim

# Configure the system (fstab, chroot, time, localization, etc.)
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
echo "arch" > /etc/hostname

# Initramfs
mkinitcpio -P

# Grub (bootloader)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable

grub-mkconfig -o /boot/grub/grub.cfg

# NetworkManager
systemctl enable NetworkManager.service
EOF

echo "Digite a senha de root para o novo sistema:"
arch-chroot /mnt passwd

echo "Instalação concluída! Execute 'umount -R /mnt' e reinicie."
