---
name: linux-audio-troubleshooting
description: Use when fixing PipeWire audio crackling or USB glitches.
---

# Linux Audio Troubleshooting (PipeWire & USB Headsets)

## Overview
Procedures for fixing audio crackling, static, or short-circuit artifacts on startup in Linux caused by PipeWire sample rate mismatch or dynamic buffer renegotiation on USB/Type-C audio devices.

## PipeWire Clock & Quantum Fix for USB Headsets
When USB or Type-C audio devices crackle or produce static on startup due to buffer renegotiation:
1. Create user configuration directory:
   ```bash
   mkdir -p ~/.config/pipewire
   cp /usr/share/pipewire/pipewire.conf ~/.config/pipewire/
   ```
2. Set fixed clock rates and quantum in `~/.config/pipewire/pipewire.conf`:
   ```text
   default.clock.rate          = 48000
   default.clock.allowed-rates = [ 48000 ]
   default.clock.quantum       = 512
   default.clock.min-quantum   = 512
   default.clock.max-quantum   = 1024
   ```
3. Restart user services:
   ```bash
   systemctl --user restart pipewire wireplumber pipewire-pulse
   ```

## USB Headset Mapped to Wrong Profile (AC3 5.1 instead of Analog Stereo)
Symptom: "ugly"/distorted sound from a USB headset even though PipeWire is fine.
Root cause: WirePlumber maps the USB device to a digital profile like
`iec958-ac3-surround-51` (6ch compressed AC3) when the hardware is actually a
stereo headset (the ALSA stream exposes `Channels: 2`, `Channel map: FL FR`).

Diagnose:
- `pactl list sinks short` → sink name ends in `iec958-ac3-surround-51` and shows `6ch`
- `cat /proc/asound/cardN/stream0` → the Playback interface exposes `Channels: 2` (stereo PCM)
- `pactl list cards` → only one profile offered: `output:iec958-ac3-surround-51`

Fix: force a profile-set that generates `analog-stereo`. Add a rule to
`~/.config/wireplumber/wireplumber.conf.d/` (append to the existing
`monitor.alsa.rules` array rather than overwriting it — use the exact
`device.name` from `wpctl inspect <id>`):

```lua
monitor.alsa.rules = [
  {
    matches = [
      {
        device.name = "alsa_card.usb---_KTMicro_--_Audio_hs_2.0_headset_2024-05-21-0000-0000-0000-00"
      }
    ]
    actions = {
      update-props = {
        device.profile-set = "simple-headphones-mic.conf"
      }
    }
  }
]
```

Then:
```bash
systemctl --user restart wireplumber
pactl list sinks short          # now shows .analog-stereo with 2ch
pactl set-default-sink <card>.analog-stereo
```

Profile-sets live in `/usr/share/alsa-card-profile/mixer/profile-sets/`
(`simple-headphones-mic.conf` emits `analog-stereo` + `stereo-fallback`;
`analog-only.conf` and `usb-gaming-headset.conf` are alternatives). Verify the
correct profile-set filename exists before referencing it.

Pitfall: the `device.name` embeds the USB serial/date and changes if the device
is re-enumerated — prefer a wildcard match if the name is unstable.
