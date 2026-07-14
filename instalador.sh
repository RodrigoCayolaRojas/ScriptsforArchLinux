#!/bin/bash
# Script de instalación automatizada y optimizada de Arch Linux para Bolivia

set -e # Detener si ocurre algún error

echo "=== 1. Limpiando y Formateando Particiones ==="
# Desmontar todo lo anterior por seguridad
umount -R /mnt 2>/dev/null || true

# Formatear la partición EFI de 500 MB en FAT32
mkfs.vfat -F 32 /dev/sda5

# Formatear la partición de 196.9 GB en EXT4
mkfs.ext4 -F /dev/sda6

echo "=== 2. Realizando Montajes Limpios ==="
mount /dev/sda6 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda5 /mnt/boot/efi

echo "=== 3. Instalando Sistema Base y Controladores Optimizados ==="
# Instalamos base, linux, firmware, intel-ucode (para tu i3),
# drivers de video libres (mesa y nouveau para tu GT 730 GF108) y soporte de red/herramientas básicas.
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode mesa xf86-video-nouveau lib32-mesa nano networkmanager sudo git xdg-user-dirs

echo "=== 4. Generando Fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== 5. Configurando el Entorno de Sistema (Chroot) ==="
arch-chroot /mnt /bin/bash <<EOF
set -e

# Configurar Zona Horaria (Bolivia)
ln -sf /usr/share/zoneinfo/America/La_Paz /etc/localtime
hwclock --systohc

# Configurar Idioma y Teclado en Latinoamericano
echo "es_BO.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_BO.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf

# Nombre de tu PC
echo "omarchy-pc" > /etc/hostname

# Añadir soporte temprano en el arranque para tu Hub USB 3.0 PCI (módulo xhci_pci)
sed -i 's/MODULES=(/MODULES=(xhci_pci /g' /etc/mkinitcpio.conf
mkinitcpio -P

# Habilitar el servicio de Internet automáticamente al iniciar
systemctl enable NetworkManager

# Configurar contraseña del administrador (Root) temporal: "root123"
echo "root:root123" | chpasswd

# Crear tu usuario administrador con acceso total para instalar Omarchy
# El usuario se llamará "omarchy" y su contraseña temporal será "bolivia123"
useradd -m -G wheel -s /bin/bash omarchy
echo "omarchy:bolivia123" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Instalar y Configurar GRUB (Añadiendo detección para tu Windows)
pacman -S --noconfirm grub efibootmgr os-prober
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Clonar los instaladores de Omarchy dentro de la carpeta personal de tu usuario
echo "=== Preparando Instalador de Omarchy ==="
cd /home/omarchy
git clone https://github.com/omarrodriguezz/omarchy.git || true
chown -R omarchy:omarchy /home/omarchy/omarchy

EOF

echo ""
echo "=========================================================="
echo "      ¡INSTALACIÓN BASE COMPLETADA CON ÉXITO!            "
echo "=========================================================="
echo "  * Tu teclado quedó configurado en Latinoamericano."
echo "  * Tu tarjeta gráfica Nvidia GT 730 tiene listos sus drivers."
echo "  * Tu Hub USB 3.0 por PCI cargará desde el inicio."
echo "  * Usuario creado: omarchy   | Contraseña: bolivia123"
echo "  * Usuario root: root         | Contraseña: root123"
echo "=========================================================="
echo "Escribe: reboot   (retira la memoria USB al reiniciarse)"
