#!/bin/sh
trap '' 2
timedatectl set-ntp true
#Get the disk
#Проверка блочного уст-ва
#True if FILE exists and is a block-special file.
if [ -b /dev/sda ]; then DISK="/dev/sda"; fi

# Partition all of main drive
echo -e "o\nn\np\n1\n\n\nw\n" | fdisk $DISK

# Format and mount drive
mkfs -F -t ext4 $DISK"1"
mount $DISK"1" /mnt

#Install base ARCH system
pacstrap /mnt base base-devel linux linux-firmware --noconfirm

#Create fstab file
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt useradd -m -g users -G audio,games,lp,optical,power,scanner,storage,video,wheel -s /bin/bash ads
arch-chroot /mnt passwd ads
arch-chroot /mnt pacman -S xorg-server dhcpcd xorg-xinit xorg-apps mesa-libgl xterm xf86-video-vesa cinnamon arc-icon-theme arc-gtk-theme file-roller gvfs-smb samba cifs-utils sddm firefox mc chromium alsa-utils  gnome-terminal gthumb vlc audacious gedit htop screenfetch --noconfirm
arch-chroot /mnt systemctl enable sddm.service
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt /bin/bash -c '
if [ -b /dev/sda ]; then DISK="/dev/sda"; fi
echo "KEYMAP=us" > /etc/vconsole.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
localectl set-keymap ru
setfont cyr-sun16
localectl set-locale LANG="ru_RU.UTF-8"
export LANG=ru_RU.UTF-8
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
locale-gen
ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
sudo hwclock --hctosys --localtime
# Set the root password
echo "root:1" | chpasswd
# Install Grub
grub-install $DISK
echo GRUB_DISABLE_SUBMENU=y >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
# Ensure DHCP service can start
systemctl enable dhcpcd.service
systemctl start dhcpcd
'
umount -R /mnt
reboot
