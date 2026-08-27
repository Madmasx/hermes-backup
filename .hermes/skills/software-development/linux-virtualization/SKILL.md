---
name: linux-virtualization
description: Use when setting up KVM and virt-manager on Linux.
category: software-development
---

# Linux Virtualization (KVM, QEMU, Libvirt, Virt-Manager)

Use this skill when installing and configuring local hardware-accelerated virtualization on Linux distributions (especially rolling/testing releases like Debian Trixie).

## 1. Installation & Setup
To install standard KVM virtualization and graphical management:
```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
```

## 2. User Permissions
Add your user to the `libvirt` and `kvm` groups so you can manage VMs without root:
```bash
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
newgrp kvm
```

## 3. Starting the Service
Enable and start the libvirt daemon:
```bash
sudo systemctl enable --now libvirtd
```

## 4. Troubleshooting Rolling/Testing Repositories (404 Not Found)
When package versions desync in rolling or testing distros (e.g. Debian Trixie):
1. Clean old package lists and caches:
   ```bash
   sudo apt clean
   sudo rm -rf /var/lib/apt/lists/*
   sudo apt update
   ```
2. Fix broken dependencies:
   ```bash
   sudo apt --fix-broken install
   ```

## 5. Storage Management (Avoiding /var space exhaustion)
Default libvirt storage pools often point to `/var/lib/libvirt/images`, which may have limited free space on some setups. For resource-heavy VMs (like Windows 11 / Photoshop requiring 60+ GB):
1. Create a custom storage pool in `virt-manager` pointing to a directory in `/home` (e.g., `/home/username/VMs`).
2. In `virt-manager`: Edit > Connection Details > Storage > Add Pool (`+`) -> Type: `dir: Filesystem Directory` -> Target Path: `/home/username/VMs`.
3. Allocate sufficient RAM (8GB-16GB) and CPU cores (6-8 cores) for graphical workloads like Adobe Photoshop.

## 6. Troubleshooting common runtime errors

### virt-manager can't connect / ISO won't attach
After a fresh install or reboot the daemon is often INACTIVE, and virt-manager then
fails with "Failed to connect" or errors when you pick an install ISO. Check and fix:
```bash
systemctl is-active libvirtd          # often "inactive"
sudo systemctl enable --now libvirtd
```
Debian ships the MONOLITHIC `libvirtd`, not the split daemons — `systemctl enable
virtqemud` errors with `Unit virtqemud.service does not exist`; just enable
`libvirtd`. Also confirm the user is in `libvirt` and `kvm` groups (`groups $USER`).

### Storage pool "Permission denied" on start
A fresh default pool can fail with
`cannot open directory '/var/lib/libvirt/images': Permission denied` because the
dir ships with perms `drwx--x--x` (0711). Fix and start:
```bash
sudo chmod 0755 /var/lib/libvirt/images
virsh pool-define-as default dir - - - - /var/lib/libvirt/images
virsh pool-start default && virsh pool-autostart default
```

### Install ISO on a FUSE/NTFS mount — verify real read access
If the Windows/install ISO lives under a ntfs-3g `fuseblk` mount (e.g. a shared
WindowsData partition), confirm the qemu user can actually read BYTES — `test -r`
can pass while FUSE still blocks the real read:
```bash
sudo -u libvirt-qemu head -c 2048 /path/to/windows.iso | wc -c   # must print 2048
```
If it returns 0, move the ISO to a local fs, or ensure the mount uses `allow_other`
plus `/etc/fuse.conf` `user_allow_other` so the qemu user can traverse it.
