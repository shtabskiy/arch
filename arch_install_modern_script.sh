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

# Спрашиваем имя пользователя
read -p "Enter username to create: " USERNAME

arch-chroot /mnt useradd -m -g users -G audio,games,lp,optical,power,scanner,storage,video,wheel -s /bin/bash "$USERNAME"
arch-chroot /mnt passwd "$USERNAME"
arch-chroot /mnt pacman -S sudo xorg-server grub dhcpcd xorg-xinit xorg-apps mesa-libgl xterm xf86-video-vesa cinnamon arc-icon-theme arc-gtk-theme file-roller gvfs-smb samba cifs-utils sddm firefox mc chromium alsa-utils  gnome-terminal gthumb vlc networkmanager-openvpn network-manager-applet audacious gedit htop screenfetch --noconfirm
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
#ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
#sudo hwclock --hctosys --localtime
timedatectl set-timezone Europe/Moscow
# Add user to sudo
echo "'"$USERNAME"' ALL=(ALL) ALL" >> /etc/sudoers
# Install Grub
grub-install $DISK
#echo GRUB_DISABLE_SUBMENU=y >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
# Ensure DHCP service can start
systemctl enable dhcpcd.service
systemctl start dhcpcd
echo "root:12345" | chpasswd
#su -c "sudo pacman -S --needed git base-devel --noconfirm && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm" -s /bin/bash '"$USERNAME"'
'
umount -R /mnt
reboot
