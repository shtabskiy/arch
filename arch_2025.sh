#!/bin/bash

# Отмена прерывания (Ctrl+C)
trap '' 2

# Обновление системных часов
timedatectl set-ntp true

# Определение диска для установки
echo "Доступные диски:"
lsblk
read -p "Введите диск для установки (например, /dev/sda): " disk

# Проверка блочного устройства
if [ ! -b "$disk" ]; then
    echo "Ошибка: $disk не является блочным устройством."
    exit 1
fi

# Разметка диска
(
  echo g # Создать новую таблицу GPT
  echo n # Новый раздел
  echo 1 # Первый раздел
  echo   # Принять значение по умолчанию (начало)
  echo +512M # Размер раздела /boot/efi
  echo t # Изменить тип раздела
  echo 1 # Установить тип раздела в EFI System
  echo n # Новый раздел
  echo 2 # Второй раздел
  echo   # Принять значение по умолчанию (начало)
  echo   # Принять значение по умолчанию (конец) - весь оставшийся объем
  echo w # Записать изменения
) | fdisk "$disk"

# Форматирование разделов
boot_partition="${disk}1"
root_partition="${disk}2"

mkfs.fat -F32 "$boot_partition"
mkfs.ext4 "$root_partition"

# Монтирование файловых систем
mount "$root_partition" /mnt
mkdir -p /mnt/boot/efi
mount "$boot_partition" /mnt/boot/efi

# Установка основных пакетов
pacstrap /mnt base linux linux-firmware vim networkmanager sudo --noconfirm

# Генерация fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Настройка системы
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локализация
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf

# Настройка сети
echo "archlinux" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\tarchlinux.localdomain\tarchlinux" > /etc/hosts

# Установка пароля root
echo "Установите пароль для root:"
passwd

# Создание пользователя
read -p "Введите имя пользователя: " username
useradd -m -G wheel -s /bin/bash "\$username"
passwd "\$username"

# Настройка sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Установка GRUB
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Установка дополнительных пакетов
pacman -S --noconfirm xorg-server xorg-xinit mesa-libgl xterm xf86-video-vesa cinnamon arc-icon-theme arc-gtk-theme file-roller gvfs-smb samba cifs-utils sddm firefox mc chromium alsa-utils gnome-terminal gthumb vlc networkmanager-openvpn nm-applet audacious gedit htop screenfetch

# Включение служб
systemctl enable sddm.service
systemctl enable NetworkManager.service

EOF

# Выход из chroot и перезагрузка
umount -R /mnt
reboot
