# Linux: Boot UEFI Dual or Single

## BIOS Prerequisite
- Disable Secure-Boot

## Disk Partitioning

### Partition Dual BIOS + UEFI Bootable Disk
- EF02 Bios-Boot (Grub core)
- EF00 EFI System
- BF01 ZFS Root

```
sgdisk --zap-all \
  --new 1::+1M   --typecode=1:EF02 \
  --new 2::+700M --typecode=2:EF00 \
  --new 3::0     --typecode=3:BF01 \
  /dev/disk/by-id/DISK
```

### Partition Single UEFI Bootable Disk
- EF00 EFI System
- BF01 ZFS Root

```
sgdisk --zap-all \
  --new 1::+700M --typecode=1:EF00 \
  --new 2::0     --typecode=2:BF01 \
  /dev/disk/by-id/DISK
```

## UEFI Setup

### Setup /boot/efi vfat mount

```
mkdir /boot/efi
mount /dev/disk/by-id/ata-QEMU_HARDDISK_QM00007-part2 /boot/efi
blkid /dev/disk/by-id/ata-QEMU_HARDDISK_QM00007-part2

vi /etc/fstab
  # was /dev/disk/by-id/ata-QEMU_HARDDISK_QM00007-part2
  UUID=9F32-F032 /boot/efi       vfat    umask=0077      0       1

systemctl daemon-reload
umount /boot/efi
mount /boot/efi
```

### Install Debian/Ubuntu Grub-EFI Packages

```
dpkg -P grub-pc grub-pc-bin
rm -rf /boot/grub/i386-pc
sudo apt install grub-pc-bin efibootmgr grub-efi-amd64 grub-efi-amd64-bin grub-efi-amd64-signed -y
```

### Install Dual BIOS + UEFI Bootable Disk
```
grub-install --target=i386-pc --force-file-id /dev/disk/by-id/DISK
update-grub
mkdir -p /boot/efi/EFI/debian
grub-install --target=x86_64-efi --removable --force-file-id --efi-directory=/boot/efi --bootloader-id=debian
```

### Install Single UEFI Bootable Disk
```
update-grub
mkdir -p /boot/efi/EFI/debian
grub-install --target=x86_64-efi --removable --force-file-id --efi-directory=/boot/efi --bootloader-id=debian
```

### Check if installed
```
ls -la /boot/grub/
ls -la /boot/efi/EFI/debian
```

