---
name: yazi
description: "Use when installing or configuring yazi (TUI file manager)."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [yazi, file-manager, tui, terminal, rust]
    related_skills: [terminal-multiplexers]
---

# Yazi (terminal file manager)

Rust TUI file manager the user adopted to replace nnn. Multi-pane layout with
image/video previews.

## When to Use

- Installing or upgrading yazi.
- Configuring keymaps, theme, or previews.
- Previews/search don't work ("no preview", "can't find files").

## Install on Debian (no apt package)

`apt-cache search yazi` returns nothing on Debian trixie — install from GitHub
releases (prebuilt binary), matching the user's minimal-sudo / ~/.local/bin
preference:

```bash
cd /tmp
curl -sL -o yazi.zip \
  "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
unzip -o yazi.zip -d yazi-extract
D=yazi-extract/yazi-x86_64-unknown-linux-gnu
install -Dm755 "$D/yazi" ~/.local/bin/yazi
install -Dm755 "$D/ya"    ~/.local/bin/ya
# bash completions (user uses Bash)
mkdir -p ~/.local/share/bash-completion/completions
cp "$D/completions/yazi.bash" ~/.local/share/bash-completion/completions/yazi
cp "$D/completions/ya.bash"    ~/.local/share/bash-completion/completions/ya
```

A `.deb` is also published (`yazi-x86_64-unknown-linux-gnu.deb`) if a system
install is preferred, but ~/.local/bin is the user's convention.

## Companion tools (required for full previews/search)

```bash
sudo apt-get install -y fd-find fzf chafa
```

- `fd` — fast find (search + file finding)
- `fzf` — fuzzy picker
- `chafa` — image previews in the terminal
- `file`, `rg`, `jq`, `unzip`, `7z` are already present on this box.

### Debian gotcha: fd is named `fdfind`

Debian's `fd-find` package installs the binary as `/usr/bin/fdfind`, but yazi
(and most tools) expect `fd`. Create a symlink:

```bash
ln -sf /usr/bin/fdfind ~/.local/bin/fd
```

Without this, yazi falls back to a slower built-in search or reports fd missing.

## User preferences (apply when configuring)

- **Theme: Dracula** — the user uses Dracula for WezTerm and Vim; match yazi to it.
- **Vim-style keymap** — consistent with their WezTerm keybindings (h/j/k/l,
  Ctrl+Shift+cursors navigation, Alt+Shift+V/H pane splitting).
- Config lives at `~/.config/yazi/` (keymap.toml, theme.toml, yazi.toml).

## Keymap quick reference

| key | action |
|---|---|
| h/j/k/l / arrows | move cursor |
| l / Enter | enter dir / open |
| h / Esc | go up |
| g / G | top / bottom |
| v | visual (select) mode |
| Space | toggle selection |
| o | open with default app |
| q | quit |
| ~ | shell mode |
| `ya` | CLI companion (e.g. `ya pack` for plugins) |

## Notes

- `yazi --version` works non-interactively for verification; launching the TUI
  needs a real terminal (like tmux) if you must drive it programmatically.
