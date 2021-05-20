#!/bin/bash

set -e

pacman -Sy --noconfirm --needed dialog

COLOR='\033[1;33m'
NC='\033[0m'

keymap=$(dialog --stdout --inputbox "Keyboard Layout:" 0 0 us)
loadkeys $keymap

hostname=$(dialog --stdout --inputbox "Hostname: " 0 0 arch-linux)
username=$(dialog --stdout --inputbox "Username: " 0 0 user)

user_password1=$(dialog --stdout --insecure --passwordbox "Enter User Password: " 0 0)
user_password2=$(dialog --stdout --insecure --passwordbox "Repeat User Password: " 0 0)
while [[ "$user_password1" != "$user_password2" || "$user_password1" == "" || "$user_password2" == "" ]]
do
  dialog --stdout --msgbox "Password is empty or passwords do not match!" 0 0
  user_password1=$(dialog --stdout --insecure --passwordbox "Enter User Password: " 0 0)
  user_password2=$(dialog --stdout --insecure --passwordbox "Repeat User Password: " 0 0)
done

root_password1=$(dialog --stdout --insecure --passwordbox "Enter ROOT Password: " 0 0)
root_password2=$(dialog --stdout --insecure --passwordbox "Repeat ROOT Password: " 0 0)
while [[ "$root_password1" != "$root_password2" || "$root_password1" == "" || "$root_password2" == "" ]]
do
  dialog --stdout --msgbox "Password is empty or passwords do not match!" 0 0
  root_password1=$(dialog --stdout --insecure --passwordbox "Enter ROOT Password: " 0 0)
  root_password2=$(dialog --stdout --insecure --passwordbox "Repeat ROOT Password: " 0 0)
done

timezone=$(dialog --stdout --inputbox "Timezone:" 0 0 Europe/Helsinki)

lang=$(dialog --stdout --inputbox "LANG " 0 0 en_US.UTF-8)
lc_time=$(dialog --stdout --inputbox "LC_TIME " 0 0 en_GB.UTF-8)

swap_size=$(dialog --stdout --inputbox "Swap size:" 0 0 16G)

encryption_password1=$(dialog --stdout --insecure --passwordbox "Enter Encryption Password: " 0 0)
encryption_password2=$(dialog --stdout --insecure --passwordbox "Repeat Encryption Password: " 0 0)
while [[ "$encryption_password1" != "$encryption_password2" || "$encryption_password1" == "" || "$encryption_password2" == "" ]]
do
  dialog --stdout --msgbox "Encryption Password is empty or passwords do not match!" 0 0
  encryption_password1=$(dialog --stdout --insecure --passwordbox "Enter Encryption Password: " 0 0)
  encryption_password2=$(dialog --stdout --insecure --passwordbox "Repeat Encryption Password: " 0 0)
done

target_disk=$(dialog --clear --title "Harddisk" --radiolist "Select target device" 0 0 0 \
$(ls /dev/sd? /dev/vd? /dev/mmcblk? /dev/nvme?n? -1 2> /dev/null | while read line; do
echo "$line" "$line" on; done) 3>&1 1>&2 2>&3)

if grep -q "mmcblk" <<< $target_disk || grep -q "nvme" <<< $target_disk; then
		disk_append=p
fi

echo -e "${COLOR}Wiping drive${NC}"
sgdisk --zap-all $target_disk

echo -e "${COLOR}Partitioning disk${NC}"
parted $target_disk -s mklabel gpt
parted $target_disk -s mkpart ESP fat32 1MiB 1025MiB
parted $target_disk -s set 1 boot on
parted $target_disk -s mkpart primary 1025MiB 100%

echo -e "${COLOR}Creating boot fs${NC}"
mkfs.fat -F 32 -n EFIBOOT ${target_disk}${disk_append}1

echo -e "${COLOR}Setting up cryptographic volume${NC}"
mkdir -p -m0700 /run/cryptsetup
echo "$encryption_password1" | cryptsetup -q -h sha512 -s 512 --use-random --type luks2 luksFormat ${target_disk}${disk_append}2
echo "$encryption_password1" | cryptsetup luksOpen ${target_disk}${disk_append}2 luks
echo -e "${COLOR}Creating volume group and logical volumes${NC}"
pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate -L ${swap_size} vg0 -n swap
lvcreate -l 90%FREE vg0 -n root

echo -e "${COLOR}Creating swap and root fs${NC}"
mkswap /dev/vg0/swap
mkfs.ext4 -F /dev/vg0/root

echo -e "${COLOR}Mounting${NC}"
mount /dev/vg0/root /mnt
mkdir /mnt/boot
mount ${target_disk}${disk_append}1 /mnt/boot
swapon /dev/vg0/swap

echo -e "${COLOR}Updating mirrorlist${NC}"
reflector --protocol https --verbose --latest 30 -a 6 --number 20 --sort rate --save /etc/pacman.d/mirrorlist

echo -e "${COLOR}Installing system and packages${NC}"
yes '' | pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware efibootmgr grub lvm2 device-mapper e2fsprogs dosfstools intel-ucode cryptsetup fwupd acpi_call acpid tlp iwd networkmanager netctl openbsd-netcat dnsutils whois dhcpcd openssh man-db man-pages texinfo neovim git wget curl reflector zsh dialog unzip iptables-nft

echo -e "${COLOR}Generating fstab${NC}"
genfstab -p /mnt >> /mnt/etc/fstab
sed -i '/^\/dev\/mapper\/vg0-root/ s/relatime/noatime/' /mnt/etc/fstab

echo -e "${COLOR}Adding hooks and modules${NC}"
sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems resume keyboard fsck)/g' /mnt/etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(ext4 intel_agp i915)/' /etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

echo -e "${COLOR}Adding kernel options${NC}"
kernel_options="GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=${target_disk}${disk_append}2:luks:allow-discards resume=/dev/vg0/swap mem_sleep_default=deep i915.enable_psr=0 i915.enable_fbc=1 i915.enable_guc=2\""
escaped_kernel_options=$(printf '%s\n' "$kernel_options" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT.*/$escaped_kernel_options/g" /mnt/etc/default/grub

echo -e "${COLOR}Creating hosts file${NC}"
echo "${hostname}" > /mnt/etc/hostname
touch /mnt/etc/hosts
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
echo "127.0.1.1 ${hostname}.localdomain ${hostname}" >> /mnt/etc/hosts

echo -e "${COLOR}Configuring time and locale${NC}"
ln -sf /usr/share/zoneinfo/$timezone /mnt/etc/localtime
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt hwclock --systohc
echo "KEYMAP=${keymap}" > /mnt/etc/vconsole.conf
echo "${lang} UTF-8" >> /mnt/etc/locale.gen
echo "${lc_time} UTF-8" >> /mnt/etc/locale.gen
echo "LANG=${lang}" >> /mnt/etc/locale.conf
echo "LC_TIME=${lc_time}" >> /mnt/etc/locale.conf
arch-chroot /mnt locale-gen

echo -e "${COLOR}Creating user and adding to sudoers${NC}"
arch-chroot /mnt useradd -m -G wheel -s /usr/bin/zsh "${username}"
echo "$username:$user_password1" | arch-chroot /mnt chpasswd
echo "root:$root_password1" | arch-chroot /mnt chpasswd
sed -i '/#\s*%wheel ALL=(ALL) ALL$/ c %wheel ALL=(ALL) ALL' /mnt/etc/sudoers

echo -e "${COLOR}Installing grub${NC}"
arch-chroot /mnt grub-install --bootloader-id=GRUB --efi-directory=/boot --target=x86_64-efi --recheck
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo -e "${COLOR}Enabling systemd services${NC}"
arch-chroot /mnt systemctl enable NetworkManager
systemctl enable reflector.timer
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable acpid
arch-chroot /mnt systemctl enable tlp

umount -R /mnt
swapoff -a

echo -e "${COLOR}Installation complete, eject install media and reboot${NC}"
