---
name: waydroid
description: Use when managing Waydroid, starting sessions under X11 via Weston, and installing APKs on Debian 13.
---

# Waydroid Management (Debian 13 / X11 Weston Setup)

## Trigger Conditions
Use this skill when starting Waydroid on X11 with Weston, managing networking with UFW, and installing standard APKs or APKM bundles.

## 1. Starting Waydroid (X11 + Weston Workflow)
Since Debian 13 runs X11 by default on your hardware, Waydroid requires Weston as a container compositor:

1. Start the backend container:
   ```bash
   sudo systemctl start waydroid-container
   ```
2. Launch Weston with the X11 backend and pixman software rendering (this prevents parent Wayland compositor connection errors and hybrid graphics/cursor corruption):
   ```bash
   unset WAYLAND_DISPLAY
   weston -B x11-backend.so --use-pixman &
   ```
3. Export the active Wayland display and start the Waydroid session:
   ```bash
   export WAYLAND_DISPLAY=$(ls /run/user/1000/wayland-* 2>/dev/null | grep -o 'wayland-[0-9]*' | tail -n 1)
   waydroid session start &
   ```
4. Wait a few seconds for Android to initialize, then show the UI:
   ```bash
   waydroid show-full-ui &
   ```

## 2. Closing Waydroid
To cleanly stop the session and container:
```bash
waydroid session stop
sudo systemctl stop waydroid-container
pkill weston
```

## 3. Installing APKs and .apkm Bundles
- **Standard APK:**
  ```bash
  waydroid app install /path/to/app.apk
  ```
- **APKM Bundles (from APKMirror):**
  Extract the split package first, then install the base and architecture/language splits:
  ```bash
  mkdir -p /tmp/apkm_extracted && cd /tmp/apkm_extracted
  unzip /path/to/app.apkm
  waydroid app install base.apk
  waydroid app install split_config.es.apk
  waydroid app install split_config.arm64_v8a.apk
  ```

## 4. Networking & Firewall (Debian 13 / UFW)
If Waydroid has no internet connection or firewall rules block `waydroid0`:
1. Allow traffic on UFW:
   ```bash
   sudo ufw allow in on waydroid0
   ```
2. If `dnsmasq` conflicts with the bridge gateway, kill conflicting processes and restart networking:
   ```bash
   sudo pkill dnsmasq
   sudo /usr/lib/waydroid/data/scripts/waydroid-net.sh start
   ```

## 5. Clipboard & Input Synchronization
To enable seamless clipboard sharing and reliable host keyboard input mapping:
```bash
sudo waydroid prop set persist.waydroid.clipboard_sharing true
sudo waydroid prop set persist.waydroid.vkeyboard false
```

## 7. Hybrid Graphics / Multi-GPU Workarounds (Intel + NVIDIA)
When launching Waydroid on hardware with hybrid graphics (e.g., Intel Iris Xe + NVIDIA RTX), X11 Weston sessions may render a black screen with a cursor or hanging terminal cursor (`_`) due to mismatched rendering contexts.
- Force software rendering and explicit display targeting via pixman:
  ```bash
  export WLR_RENDERER=pixman
  export WAYLAND_DISPLAY=wayland-0
  weston -B x11-backend.so --use-pixman &
  ```
- Use a robust startup wrapper script stored at `~/.local/bin/start-waydroid-nvidia.sh` to encapsulate the cleanup, backend initialization, and Weston environment setup.
