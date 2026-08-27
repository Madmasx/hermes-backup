# Worked example: uninstalling aura-glass (GNOME macOS/Tahoe glass ricing)

Repo: https://github.com/DevWebeloper/aura-glass — a "frosted glass" GNOME 48-50
ricing. This session the user asked to uninstall a *different* repo
(Gradient-Plasma-Themes, a KDE Plasma theme) that turned out NOT to be
installed; the actually-installed project was aura-glass. Always verify first.

## What aura-glass installs (the full footprint to expect from such repos)
- CSS blocks appended to `~/.themes/Tahoe-Dark/gnome-shell/gnome-shell.css` and
  `~/.config/gtk-4.0/{gtk.css,gtk-dark.css}`, `~/.config/gtk-3.0/gtk.css`
  (marker comments `/* >>> aura-glass BEGIN <<< */` … `END`).
- Backups of overwritten files in `~/.config/aura-glass/backups/` (`.orig` and
  `.absent` markers for files it created from nothing).
- gsettings: `gtk-theme`, `icon-theme`, `cursor-theme`, `accent-color`.
- dconf: `reset -f /org/gnome/shell/extensions/{openbar,blur-my-shell,custom-osd,user-theme,just-perfection,gnome-ui-tune,space-bar,vitals,clipboard-indicator,hotedge,appindicator}/`.
- systemd user units in `~/.config/systemd/user/`: `aura-glass-panel-blur.service`,
  `aura-glass-icon-sync.service`, `aura-glass-gdm-sync.service`.
- GNOME extensions (in `~/.local/share/gnome-shell/extensions/`): openbar, custom-osd,
  blur-my-shell, just-perfection, gnome-ui-tune, space-bar, clipboard-indicator,
  appindicatorsupport, compiz-alike-magic-lamp-effect.
- Assets: `~/.themes/Tahoe-Dark` (and Tahoe-Light), icons `~/.local/share/icons/{Colloid*,Reversal*,MacTahoe*}`.
- Helper binaries in `~/.local/bin/`: `aura-glass-*`, `tahoe-glass-*`.
- Source cache: `~/.cache/aura-glass/src/` (WhiteSur-gtk-theme, blur-my-shell, Colloid-icon-theme, …).
- Optional root/GDM (only when the install wizard answered yes): synced monitor
  layout to `/etc/xdg/monitors.xml` + `/var/lib/gdm/.config/monitors.xml` (copies
  of `~/.config/monitors.xml`), and WhiteSur GDM theming via `sudo bash tweaks.sh -g`.

## Uninstall command that worked
```bash
cd ~/aura-glass && ./uninstall.sh --all -y
```
`--all` = styling + extensions + assets + GDM revert (equiv. `--full`). `-y`
answers the "delete config dir?" confirm yes; the trailing `prompt_logout` is a
`confirm_always` which declines when run without a TTY (so it did NOT log the
user out). Output confirmed each category removed.

## Leftovers to verify manually after the uninstaller
- Root-owned GDM monitor sync files survive because the `sudo rm -f … 2>/dev/null
  || true` fails without a password. Report them; do not claim a clean wipe:
  ```bash
  sudo rm -f /etc/xdg/monitors.xml /var/lib/gdm/.config/monitors.xml
  ```
- The git clone itself (`~/aura-glass`) is NOT removed by the uninstaller — `rm -rf` it yourself.
- `user-theme` extension is deliberately left (stock GNOME extension).
- `enabled-extensions` should be clean if `gnome-extensions disable <uuid>` ran
  before each removal; verify with
  `gsettings get org.gnome.shell enabled-extensions`.

## Verification checklist (post-uninstall)
```bash
ls -1 ~/.themes                      # Tahoe-Dark gone
ls -1 ~/.local/share/icons           # only user's own (Papirus, hicolor, …)
ls ~/.local/bin | grep -iE 'aura|tahoe'   # empty
ls ~/.config/systemd/user/ | grep -iE 'aura|tahoe'   # empty
ls -d ~/.config/aura-glass ~/.cache/aura-glass        # gone
ls ~/.local/share/gnome-shell/extensions/ | grep -iE 'blur|openbar|space-bar|clipboard|appindicator'
gsettings get org.gnome.desktop.interface gtk-theme   # 'Adwaita' (reset)
```

## General lesson
The theme project's own uninstaller, with the widest scope flag, is the correct
first tool — it knows its own backup markers, dconf keys, and unit names better
than any hand-written `rm -rf`. The agent's job is (a) confirm the RIGHT project
is being removed, (b) pick the right scope, (c) run it without a TTY to dodge the
logout prompt, and (d) sweep for root-owned leftovers the `|| true` sudo calls hid.
