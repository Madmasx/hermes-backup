# WaSh v2 productivity/UI patterns

Validated in the user's `~/proyectos/wash` TUI (Go/tview/whatsmeow), published as `github.com/Madmasx/wash`.

## Repo hygiene before publishing

- Runtime data lives outside the repo in `~/.config/wash/` (`session.db`, `wash.config`); do not copy those into the project tree.
- Add defensive ignores before pushing: compiled binaries (`wash`, `wash.exe`, legacy `whatscli*`) and SQLite files (`*.db`, `*.db-wal`, `*.db-shm`, `*.db-journal`).
- For a rebranded fork that should stand alone, remove upstream packaging/release leftovers (`.github/aur`, upstream release workflows/scripts, empty placeholders) but keep README credit and original license acknowledgement.

## tview autocomplete integration

- Use one input autocomplete dispatcher so all features share arrow handling:
  - command prefix (`/` or configured `cmd_prefix`) -> slash-command suggestions;
  - otherwise -> contact `@` suggestions.
- The same dispatcher must be used in `InputCapture`: when suggestions exist, return the arrow key event instead of consuming it for message-history scrolling.
- tview replaces the full input with the selected suggestion. Contact suggestions should therefore return the full resulting text (`currentText[:at+1] + name`) so text typed before `@` is preserved.
- Keep multi-word contact names matching after tview fills the field (`@Juan Pérez`), or the dropdown collapses on first arrow movement.

## Attachments without commands

- Drag/drop in terminal = pasted file path. In Enter handler, before slash-command dispatch, trim quotes/tilde, `os.Stat` the input, and if it is a regular file, map extension to the existing media command (`sendimage`, `sendvideo`, `sendaudio`, `upload`).
- Clipboard screenshots: on paste, probe clipboard targets before text paste. X11 path: `xclip -selection clipboard -t TARGETS -o`, pick `image/*`, extract bytes with `xclip -selection clipboard -t <mime> -o`, write temp file, enqueue `sendimage`. Wayland equivalent: `wl-paste --list-types` + `wl-paste --type <mime>`.
- Clipboard image probe failures should fall through silently to normal text paste.

## Verification checklist

- `export PATH=$PATH:/home/madmasx/.local/go/bin`
- `make build`
- `go test ./... -count=1`
- For README/docs, verify actual files/commands against the repo before claiming names or behavior.
