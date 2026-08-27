---
name: linux-nvidia-hybrid
description: Use when troubleshooting or configuring NVIDIA and Intel hybrid graphics on Linux, external display freezing, power management, and DRM modeset.
---

# Linux NVIDIA Hybrid Graphics & Display Troubleshooting

## Overview
Procedures and fixes for managing NVIDIA and Intel hybrid graphics laptops on Linux, specifically addressing external monitor freezes, power management, and kernel modesetting.

## Key Configurations

### 1. External Display Freezing / NVIDIA Power Management
External monitors connected to NVIDIA ports on hybrid laptops can freeze due to aggressive runtime power management (D3Cold / Dynamic Power Management).
- Check or create `/etc/modprobe.d/nvidia-pm.conf`:
  ```text
  options nvidia NVreg_DynamicPowerManagement=0x00
  ```

### 2. DRM Modeset in GRUB
To prevent desynchronization and ensure proper display handling with NVIDIA proprietary drivers:
- Edit `/etc/default/grub` and ensure `nvidia-drm.modeset=1` is passed in `GRUB_CMDLINE_LINUX_DEFAULT`:
  ```text
  GRUB_CMDLINE_LINUX_DEFAULT="quiet nvidia-drm.modeset=1"
  ```
- Update GRUB:
  ```bash
  sudo update-grub
  ```

### 3. Wayland compositors (Hyprland/Sway) on hybrid graphics
On Intel iGPU + NVIDIA dGPU laptops, run the compositor on the iGPU by default (most stable, battery-friendly) and offload heavy apps to the NVIDIA with `prime-run <app>`.
- To force the compositor to render entirely on the NVIDIA dGPU, set these env vars — in Hyprland legacy config use `env = KEY,VALUE` inside `~/.config/hypr/hyprland.conf` (Lua config uses `hl.env("KEY","VALUE")`):
  - `LIBVA_DRIVER_NAME=nvidia`
  - `GBM_BACKEND=nvidia-drm`
  - `__GLX_VENDOR_LIBRARY_NAME=nvidia`
  - `__NV_PRIME_RENDER_OFFLOAD=1`
  - `AQ_DRM_DEVICES=/dev/dri/card1` (confirm the NVIDIA node with `ls -l /dev/dri/`; usually card1 on laptops)
- `nvidia-drm.modeset=1` in GRUB (section 2) is a hard prerequisite for NVIDIA + Wayland; without it the compositor won't get a DRM device.

### 4. GDM silently disables Wayland on NVIDIA hybrid → compositor never shows in the login selector
Symptom: you register a Wayland session (Hyprland/Sway) in `/usr/share/wayland-sessions/`, set `WaylandEnable=true` in `/etc/gdm3/custom.conf`, reboot — and the session still doesn't appear / login still lands on X11. Your `custom.conf` is being **overwritten at boot**.

Root cause: `/usr/lib/udev/rules.d/61-gdm.rules` runs `gdm-runtime-config set daemon WaylandEnable false` whenever the NVIDIA driver is missing any of the "suspend/resume for working Wayland support" preconditions. The most common trigger on Debian is `NVreg_PreserveVideoMemoryAllocations` being `0`:
```text
ENV{NVIDIA_PRESERVE_VIDEO_MEMORY_ALLOCATIONS}!="1", GOTO="gdm_disable_wayland"
```
This fires even when `nvidia-sleep.sh`, `/usr/lib/systemd/system-sleep/nvidia`, and the `nvidia-suspend/resume/hibernate` services are all present and enabled — so check ALL of them, but the parameter is the one that's usually still `0`.

Fix:
```bash
# /etc/modprobe.d/nvidia-power-management.conf
options nvidia NVreg_PreserveVideoMemoryAllocations=1
```
Then **reboot** (modprobe.d only applies when the module reloads). Verify with `grep PreserveVideoMemoryAllocations /proc/driver/nvidia/params` → must return `1`. On hybrid systems this rule is arguably overkill (compositor runs on iGPU), but it gates the GDM greeter's Wayland path, so it must be satisfied.

### 5. Wayland needs the `input` and `render` groups
Running a Wayland compositor "by hand" from a TTY (not via the display manager) fails/hangs at startup if the user is only in `video`. `/dev/dri/card*` and `renderD*` get per-user ACLs from logind, but `/dev/input/event*` is owned by the `input` group and gets NO per-user ACL — so without group membership the compositor cannot open keyboard/mouse and hangs after "Welcome to Hyprland!".
```bash
sudo usermod -aG input,render <user>   # then log out/in or reboot
```
