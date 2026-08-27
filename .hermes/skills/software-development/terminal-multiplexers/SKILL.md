---
name: terminal-multiplexers
description: Use when configuring tmux terminal multiplexers.
---

# Terminal Multiplexers (tmux)

## Trigger Conditions
- User wants to install, configure, or troubleshoot `tmux` or other terminal multiplexers.
- Setting up persistent terminal sessions, window/pane splitting, and shell integration/aliases.

## Key Procedures

### 1. Installation & Version Check
- Install on Debian/Ubuntu: `sudo apt install tmux`
- Check version: `tmux -V`

### 2. Standard `~/.tmux.conf` Configuration
Create or update `~/.tmux.conf` with modern sensible defaults:
```tmux
# Activar soporte de mouse
set -g mouse on

# Colores verdaderos (True Color)
set -g default-terminal "screen-256color"
set -as terminal-features ",xterm-256color:RGB"

# Empezar índices en 1 en lugar de 0 para ventanas y paneles
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Historial ampliado
set -g history-limit 10000

# Modo vi para el modo de copia
set-window-option -g mode-keys vi

# Sin retraso en la tecla escape
set -s escape-time 0
```

### 3. Shell Aliases (`~/.bashrc`)
Add quick session management aliases for daily efficiency:
```bash
alias t="tmux"
alias ta="tmux attach -t"
alias tls="tmux ls"
alias tk="tmux kill-session -t"
```

### 4. Verification Workflow
- Test configuration parsing without blocking terminal:
  `tmux -f ~/.tmux.conf new-session -d -s test-session && tmux kill-session -t test-session`
- Test shell aliases in a non-interactive/interactive bash check.

## Pitfalls
- Ensure true color features match the terminal emulator being used (e.g., WezTerm, Alacritty) so colors and themes (like Dracula) render correctly inside tmux sessions.
