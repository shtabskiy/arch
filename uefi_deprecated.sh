#!/bin/sh
trap '' 2

#Get the disk
#Проверка блочного уст-ва 
#True if FILE exists and is a block-special file.
if [ -b /dev/sd ]; then DISK="/dev/sda"; fi

#Преобразование диска в gpt
parted $DISK "mklabel gpt Yes"

# Разбиение разделов
#echo -e "o\nn\np\n1\n\n+512M\nt\n1\nn\ne\n2\n\n\nw\n" | fdisk $DISK
echo -e "\nn\n1\n\n+512M\nt\n1\nn\n2\n\n\nw" | fdisk /dev/sda

# Format and mount drive
mkfs.fat -F32 $DISK"1"
mkfs.ext4 $DISK"2"

mount $DISK"2" /mnt
mkdir /mnt/boot
mount $DISK"1"  /mnt/boot

#Бекап конфига зеркал и создание нового кастомного файла зеркала.
mirror=`cat /etc/pacman.d/mirrorlist | grep yandex`
cp -r /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
echo $mirror > /etc/pacman.d/mirrorlist

# Install base system, fstab
pacman -Sy
pacstrap /mnt base base-devel
genfstab -pU /mnt >> /mnt/etc/fstab

# Keyboard, locale, time
arch-chroot /mnt useradd -m -g users -G audio,games,lp,optical,power,scanner,storage,video,wheel -s /bin/bash ads
arch-chroot /mnt passwd ads
arch-chroot /mnt pacman -S os-prober xorg-server xorg-xinit xorg-apps mesa-libgl xterm xf86-video-vesa cinnamon arc-icon-theme arc-gtk-theme file-roller gvfs-smb samba cifs-utils sddm firefox mc chromium alsa-utils  gnome-terminal gthumb vlc audacious gedit htop screenfetch --noconfirm
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
bootctl install
cat << EOF >> /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd /initramfs-linux.img
options root=/dev/sda2 rw
EOF
cat << EOF >> /boot/loader/loader.conf
timeout 3
default arch
EOF
# Ensure DHCP service can start
systemctl enable dhcpcd.service
systemctl start dhcpcd
'
exit
reboot
