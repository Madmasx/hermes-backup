---
name: linux-desktop-customization
description: Use when configuring Linux desktop shortcuts and gsettings.
---

# Linux Desktop Customization

## Trigger Conditions
- User wants to configure keyboard shortcuts, keybindings, or desktop utility behavior on Linux (GNOME, etc.).
- Automating desktop preference configuration via command-line tools.
- Troubleshooting GNOME Shell extensions/widgets — e.g. an invisible area that blocks clicks in windows, or a dock/panel misbehaving (dash-to-dock / dash2dock-lite).

## Key Procedures (GNOME / gsettings)

### 1. Managing Custom Keybindings
- List custom keybindings:
  `gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings`
- Add a custom keybinding (e.g., custom1):
  1. Update array of paths:
     `gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"`
  2. Set name, command, and binding:
     `gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Name'`
     `gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'command-to-run'`
     `gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding 'Print'`

### 2. Disabling Conflicting Built-in Shortcuts
- Clear built-in keybindings (e.g., default screenshot UI):
  `gsettings set org.gnome.shell.keybindings show-screenshot-ui "['']"`

### 3. Flameshot QR Code Scanning Integration
- Install `zbar-tools` (`sudo apt install zbar-tools`).
- Create a helper script to scan QR selections on screen:
  ```bash
  #!/bin/bash
  RESULT=$(flameshot gui --raw | zbarimg -q - 2>/dev/null)
  if [ -n "$RESULT" ]; then
      CONTENT=$(echo "$RESULT" | sed 's/^[^:]*://')
      echo -n "$CONTENT" | xclip -selection clipboard
      notify-send "QR Escaneado con Éxito" "$CONTENT\n(Copiado al portapapeles)"
  else
      notify-send "Escáner QR" "No se detectó ningún código QR en la selección."
  fi
  ```
- Register it as a custom keybinding (e.g. `<Shift>Print`) and/or create a `.desktop` launcher in `~/.local/share/applications/` so it appears in the app menu.

### 4. Tiling Windows and Terminal Split Shortcuts (GNOME & WezTerm)
- **GNOME Window Tiling:** Configure window snapping via mutter keybindings:
  ```bash
  gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Control><Shift>Left']"
  gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Control><Shift>Right']"
  ```
- **WezTerm Panel Splitting & Navigation:** Configure split panes and neighbor/pane navigation using `Ctrl + Shift + Arrows` and custom split bindings in `~/.config/wezterm/wezterm.lua` (especially handling Flatpak paths if applicable):
  ```lua
  config.keys = {
    { key = 'v', mods = 'ALT|SHIFT', action = wezterm.action.SplitPane { direction = 'Right' } },
    { key = 'h', mods = 'ALT|SHIFT', action = wezterm.action.SplitPane { direction = 'Down' } },
    { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down' },
  }
  ```
  - **Themes and Inline Cheat Sheets:** You can set color themes (e.g., `config.color_scheme = 'Dracula'`, `'Catppuccin Mocha'`, `'Tokyo Night'`), opacity, and embed documentation/cheat sheets directly as Lua comments inside `wezterm.lua` for quick reference. WezTerm supports live hot-reloading upon saving the config file.
- **Avoid Conflicts:** Be careful with `Ctrl + Shift + Arrow` combinations as GNOME desktop tiling bindings might conflict or move entire desktop windows if not overridden or cleared. Note also that Flatpak instances of WezTerm look for configs in `~/.var/app/org.wezfurlong.wezterm/config/wezterm/wezterm.lua` (or require permissions override via `flatpak override --user --filesystem=home`).

### 5. Setting the Default Browser (xdg-settings / Flatpak)

- Find where the browser lives first — Flatpak browsers ship a `.desktop` under `/var/lib/flatpak/exports/share/applications/` and have no binary in `/usr/bin`:
  ```bash
  flatpak list | grep -i brave          # → com.brave.Browser
  find /var/lib/flatpak/exports/share/applications -iname "*brave*"
  ```
- Set it as default (user-level, no sudo) — GNOME reads these via mimeapps.list:
  ```bash
  xdg-settings set default-web-browser com.brave.Browser.desktop
  xdg-mime default com.brave.Browser.desktop x-scheme-handler/http x-scheme-handler/https \
    x-scheme-handler/about x-scheme-handler/unknown text/html
  ```
- Verify: `xdg-settings get default-web-browser` and `xdg-mime query default x-scheme-handler/http` — both must print the new `.desktop` id. The change is immediate (no re-login needed); GNOME may cache it until re-login in edge cases.

### 5. Setting the Default Browser (xdg-settings / Flatpak)

- Find where the browser lives first — Flatpak browsers ship a `.desktop` under `/var/lib/flatpak/exports/share/applications/` and have no binary in `/usr/bin`:
  ```bash
  flatpak list | grep -i brave          # → com.brave.Browser
  find /var/lib/flatpak/exports/share/applications -iname "*brave*"
  ```
- Set it as default (user-level, no sudo) — GNOME reads these via mimeapps.list:
  ```bash
  xdg-settings set default-web-browser com.brave.Browser.desktop
  xdg-mime default com.brave.Browser.desktop x-scheme-handler/http x-scheme-handler/https \
    x-scheme-handler/about x-scheme-handler/unknown text/html
  ```
- Verify: `xdg-settings get default-web-browser` and `xdg-mime query default x-scheme-handler/http` — both must print the new `.desktop` id. The change is immediate (no re-login needed); GNOME may cache it until re-login in edge cases.

### 6. Setting the Default Terminal (gsettings + update-alternatives)
- GNOME default terminal (Ctrl+Alt+T, "open terminal", GTK apps):
  `gsettings set org.gnome.desktop.default-applications.terminal exec 'wezterm'`
  `gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e'`
- Debian `x-terminal-emulator` (CLI apps, `sensible-terminal`, Nautilus actions):
  `sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 40`
  `sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm`
- Pitfall: pick an `exec-arg` the terminal actually supports. WezTerm accepts `-e` as an alias of `wezterm start`, so `-e` works for both gsettings and the `x-terminal-emulator -e <cmd>` protocol. Verify with `<term> --help` before assuming `-e`.

### 7. Nautilus "Open Terminal Here" (nautilus-python)
- GNOME 46+ Nautilus removed the native action; Debian's `nautilus-extension-gnome-terminal` re-adds one but hardcodes gnome-terminal. To open a custom terminal (e.g. WezTerm) in the current folder:
  1. `sudo apt install python3-nautilus`
  2. Drop a script in `~/.local/share/nautilus-python/extensions/` (see `templates/nautilus-open-terminal.py`) that spawns `<terminal> start --cwd <path>`.
  3. Reload: `nautilus -q`, relaunch, and watch Nautilus stderr for `TypeError` from your extension.
- **Pitfall (signature):** nautilus-python's method signature changed across versions (with/without a leading `window` arg). The Debian 4.0.1 build calls `get_file_items(...)`/`get_background_items(...)` WITHOUT `window`, so `def get_file_items(self, window, files)` raises `TypeError: missing 1 required positional argument: 'files'`. Robust fix: `def get_file_items(self, *args): files = args[-1]` (and `def get_background_items(self, *args): current = args[-1]`).
- `Nautilus.MenuItem` has no `get_label()`; read it via `get_property('label')`.

## GNOME Shell Extensions: dash-to-dock / dash2dock-lite Troubleshooting

### Symptom: invisible area blocks clicks in a window (e.g. browser)
The dock extension leaves an invisible layer over other windows that "eats" clicks — the user can't click a region of the browser even though nothing is visibly there. Typical setup: dock at the bottom with a fully transparent background (`background-color = (0,0,0,0)`, floating-dock look) plus "intelligent autohide" enabled. In dodge/intellihide mode the dock is meant to hide when a window overlaps it, but a transparent reveal/hit layer (the ~2px "dwell" strip + the dock's own hover area) can linger and intercept pointer events over the window.

### Fix attempt 1: disable intelligent autohide (dodge)
```bash
dconf write /org/gnome/shell/extensions/dash2dock-lite/autohide-dodge false
```
Switches from "intelligent autohide" (shows on empty desktop, hides when a window overlaps) to plain autohide (always hidden unless the pointer is over the dock, macOS-style). Applies LIVE (settings-changed → `_updateAutohide()`); no shell restart needed. NOTE: this alone may NOT fix a persistent phantom click-blocking box — if the dead zone survives, the real cause is the `affectsInputRegion` struts layer (below).

### Diagnose by isolating the extension (fastest, definitive)
```bash
gnome-extensions info dash2dock-lite@icedman.github.com   # State: ACTIVE/INACTIVE
gnome-extensions disable dash2dock-lite@icedman.github.com  # immediate; re-enable after test
```
Disabling takes effect immediately and proves whether the dead zone belongs to that extension or another (suspicious alternatives on GNOME: blur-my-shell, tilingshell). On X11 a click-blocking overlay is a GNOME Shell chrome *actor*, not an X11 window — `xprop`/`xwininfo` will not reveal it.

### Reading a screenshot when the vision tool is unavailable
`vision_analyze` is not always loaded (CLI sessions may not include the `vision` toolset). To still gauge a screenshot's layout, render it as ASCII with chafa: `chafa --format symbols --colors none --size 120x24 file.png` (use `--size 160x20` for wide strips — match the image's aspect ratio). This revealed a dock's icon row without vision. To enable vision for future sessions: `hermes tools enable vision` (takes effect on `/new`/restart, not mid-session).

### Code edits vs settings: what applies live
GSettings/dconf *settings keys* apply live only for keys the extension wires to a settings-changed handler (dash2dock-lite's `autohide-dodge`/`autohide-dash` call `_updateAutohide()` immediately). *JS code edits* never apply live — after patching, reload with `gnome-extensions disable <uuid> && gnome-extensions enable <uuid>`. Verify the edit with `node --check <file>` before reloading.

### Root cause of a persistent phantom box: affectsInputRegion on the transparent struts
In `dock.js`, the dock's `struts` St.Widget is added as chrome with:
```js
Main.layoutManager.addChrome(this.struts, {
  affectsStruts: !this.extension.autohide_dash,
  ...(Config.PACKAGE_VERSION[0] == '4' ? { affectsInputRegion: true } : {}),  // GNOME 4x only
});
```
`affectsInputRegion: true` makes the ENTIRE transparent dock area part of the shell input region, so it intercepts clicks even when nothing is visible — exactly the "cuadro que no deja hacer clic". The author's own "X11 click-through fix" (enlarging struts in `animator.js`) is commented out. Fixes worth trying (verify dock icons stay clickable afterward): set `affectsInputRegion: false`, give the dock a visible background, or replace the extension. The reveal strip is a separate 2px `DockDwell` widget (`reactive: true`); struts visibility tracks autohide (`dock.struts.visible = !dock._hidden`).

### Reading/writing user-installed extension settings (dconf, not gsettings)
User-installed extensions keep their GSettings schema inside their own directory (`~/.local/share/gnome-shell/extensions/<uuid>/schemas/`), NOT in the system schema path. So `gsettings get org.gnome.shell.extensions.<name> ...` fails with `No such schema`. Use dconf against `/org/gnome/shell/extensions/<name>/` instead:
```bash
dconf dump /org/gnome/shell/extensions/dash2dock-lite/          # list all keys + values
dconf write /org/gnome/shell/extensions/dash2dock-lite/<key> <value>
```
Useful dash2dock-lite keys: `autohide-dash`, `autohide-dodge`, `pressure-sense`, `pressure-sense-sensitivity`, `edge-distance`, `dock-location` (0=bottom, 1=left, 2=right, 3=top), `icon-size`, `icon-spacing`, `background-color`. To diagnose the invisible area, set `debug-visual=true` so the dock's hitbox is painted visibly. The extension source (`dock.js`/`autohide.js`) in its own dir is readable and documents the "dwell"/struts hit areas.

## Uninstalling desktop themes / ricing projects (GNOME, KDE Plasma, GTK)

### Trigger
User asks to "uninstall" a theme or ricing project (a GNOME glass theme, a KDE global theme, a dotfiles ricing repo). FIRST verify what is actually installed — users frequently misname the theme or link a repo that was never installed. (Real case: user asked to remove "Gradient-Plasma-Themes", which was nowhere on disk; the actually-installed project was "aura-glass".) Confirm before deleting.

### 1. Discover what's actually installed (search every standard location)
- KDE Plasma: `~/.local/share/plasma/desktoptheme`, `~/.local/share/plasma/look-and-feel`, `~/.local/share/color-schemes`, `~/.local/share/aurorae/themes`, `~/.local/share/kpackage`, plus `/usr/share/` equivalents.
- GNOME/GTK: `~/.themes`, `~/.icons`, `~/.local/share/icons`, `~/.local/share/themes`, `/usr/share/themes`, `/usr/share/icons`.
- Also check: `~/.local/share/gnome-shell/extensions/`, `~/.config/systemd/user/` (user units), `~/.local/bin` (helper binaries), `~/.cache/<project>/src` (source cache), and grep `~/.bash_history` for the `git clone` / `./install.sh` that installed it.
- Active theme state: `gsettings get org.gnome.desktop.interface gtk-theme|icon-theme|cursor-theme|accent-color`.

### 2. Prefer the project's own uninstaller
Most ricing repos ship an `uninstall.sh`. Run it from the repo root with the widest scope (e.g. `./uninstall.sh --all -y` — confirm flag names via `--help`). It restores its own backups, resets gsettings/dconf, and removes its systemd units, extensions, assets, and binaries — far safer than hand-deleting. READ `uninstall.sh` and its `lib/*.sh` first to understand the scope flags (`--all` vs styling-only) and what "full" actually deletes.

### 3. Pitfalls
- **Logout risk:** uninstall scripts often end with a `prompt_logout` that runs `loginctl terminate-session` / `gnome-session-quit`. With `-y` in a real TTY this can KILL the user's session. A well-written `confirm_always` declines when stdin is not a TTY. Verify this before passing an auto-yes flag; prefer running WITHOUT a pty so the logout prompt declines itself.
- **sudo silently fails:** GDM/root steps use `sudo ... 2>/dev/null || true`, so they print "✓" while doing nothing when passwordless sudo isn't available. After the uninstaller, check for root-owned leftovers and report them honestly (e.g. `/etc/xdg/monitors.xml`, `/var/lib/gdm/.config/monitors.xml`, `/usr/share/backgrounds/*-gdm.png`) rather than claiming a clean removal.
- **cwd breakage:** if you `cd` into the repo and then delete the repo, the shell's cwd is gone — run `cd ~` before further commands.
- **Scope matters:** the full uninstall also removes extensions and icon themes the project installed (e.g. blur-my-shell, Colloid/MacTahoe icons), resets gsettings to defaults (Adwaita), and leaves stock extensions like `user-theme` alone. If the user has their own unrelated extensions mixed in, those are untouched because the uninstaller only touches `~/.local/share/gnome-shell/extensions/` (never `/usr/share`).

See `references/aura-glass-uninstall.md` for the full worked example.

### 8. Hyprland Environment Utilities (Hyprlock, Hypridle, Hyprshot, Hyprsunset)
- **Hypridle & Hyprlock:** Configure idle timeouts in `~/.config/hypr/hypridle.conf` (brightness dims, session locks via `hyprlock`, screens turn off via DPMS). Hyprlock handles blurred screenshots and modern aesthetic inputs (e.g. Dracula theme style).
- **Hyprshot / Grim+Slurp Wrapper:** On systems lacking native packaged `hyprshot`, use a wrapper script in `~/.local/bin/hyprshot` using `grim` and `slurp` for region/output screenshots piped to `wl-clipboard` and `notify-send`.
- **Hyprsunset:** Run `exec-once = hyprsunset -t 4500` in `hyprland.conf` for automatic blue light reduction / night mode.

- **Flameshot on X11 / Browsers:** 
  - Requires `xclip` package installed (`sudo apt install xclip`) to copy images to the clipboard.
  - Browser/WhatsApp Web clipboard paste issues: set `useJpgForClipboard=false` in `~/.config/flameshot/flameshot.ini` so images are copied as PNG rather than JPEG, ensuring compatibility with web apps and messaging clients.
- **Debian `fd` binary name:** the `fd-find` package installs the binary as `fdfind`, NOT `fd`. Tools that look for `fd` (yazi, many others) won't find it. Fix: `ln -sf /usr/bin/fdfind ~/.local/bin/fd` (verify `~/.local/bin` is in PATH). Also: prebuilt TUI tools like yazi ship GitHub release `.zip`s — unzip and drop `yazi`/`ya` into `~/.local/bin`, then install bash completions into `~/.local/share/bash-completion/completions/`.
- **Don't disable the user's extension to diagnose if they want to keep it.** When a user reports a widget/dock interfering, clarify whether they want it removed or just reduced/fixed in place — they may want the extension active and only the offending area shrunk. Prefer an in-place patch (e.g. `affectsInputRegion: false`) or size reduction over disable-and-replace; disabling is fine only as a quick isolation test that you immediately revert.
