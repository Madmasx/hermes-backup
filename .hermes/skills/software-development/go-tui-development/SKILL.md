---
name: go-tui-development
description: Use when modifying Go TUI apps (tview/whatsmeow).
---

# Go TUI Development (tview / tcell / whatsmeow)

Class-level workflow for building and debugging terminal UI apps in Go —
mainly the user's WhatsApp TUI client **wash** at `/home/madmasx/proyectos/wash`.

## Trigger Conditions
- User asks for changes to wash or a similar Go TUI app (features, i18n, fixes)
- Adding/editing UI strings, tree nodes, commands, or connection handling
- Verifying a Go TUI app builds, tests, and runs

## Toolchain Facts (this machine)
- Go is at `/home/madmasx/.local/go/bin` — **not on PATH**. Export it first:
  `export PATH=$PATH:/home/madmasx/.local/go/bin`
- System go is 1.23.6; wash's go.mod requires `go >= 1.25`. Go auto-downloads the
  toolchain — do NOT set `GOTOOLCHAIN=local` (breaks builds with a go.mod version error).
- Build: `make build` (canonical, `go build`) · Tests: `go test ./... -count=1`
  (`-count=1` to bypass cache for fresh evidence).
- `hermes verify --json` readiness phase expects an HTTP server — a TUI exposes
  none, so `overall: False` there is expected and NOT a failure. Compensate with
  real pty smoke tests (below).

## i18n Pattern (used in wash)
- Dictionary in `config/i18n.go`: `translations = map[lang]map[key]string` with
  `es` and `en`; `config.T(key)` falls back es → en → raw key.
- Language key lives in config: `General.Language` (`[general] language = es|en`),
  default `"es"`. `config.Save()` persists via `ini.ReflectFromWithMapper`
  (writes `language = en` in `[general]`).
- Runtime switching: `/lang es|en` command in `execCommand` → `setLanguage()`
  updates config + Save + `RefreshLanguage()`. `RefreshLanguage()` must update
  tree node titles AND re-print help/commands screens (PrintHelp + PrintCommands)
  so the text adjusts immediately.
- When adding a UI command, ALWAYS add its help line to BOTH `PrintHelp` (keys
  screen) and `PrintCommands` (command list) plus dictionary keys — the user
  checks both screens.
- User preference: wash UI is Spanish by default.

## tview click→text mapping & deterministic UI tests
For making text regions (URLs) inside a TextView clickable, and testing the TUI headlessly:
- tview (2021 pin) exposes NO hit-testing — replicate its render (tag stripping + word wrap) in a line index; hook `textView.SetMouseCapture` (capture runs BEFORE the InRect check; return the event unchanged to keep region highlighting). Keep the index in sync via a single logged write path (reset on Clear/SetText; sentinel for ANSI output).
- tcell SimulationScreen is double-buffered: call `screen.Show()` after `tv.Draw(screen)` or GetContents is blank. Simulate clicks by calling `tv.MouseHandler()(action, tcell.NewEventMouse(x, y, tcell.Button1, 0), setFocus)` directly — no Application loop needed.
- Verbatim tag/wrap regexes, the wrap algorithm, escape semantics (`[]`/`[[]` print literally), and the URL-span mapping: `references/tview-rendering-and-click-mapping.md`

## Verification Workflow for TUI Apps
1. `gofmt -w` changed files, then `go build ./...`, `go test ./... -count=1`.
2. Smoke test in a pty (no TTY access otherwise):
   `timeout 11 script -qec "stty rows 50 cols 140; env XDG_CONFIG_HOME=/tmp/xyz ./wash" /tmp/log >/dev/null 2>&1`
   Use a throwaway XDG_CONFIG_HOME so the user's real config is untouched.
3. Verify rendered UI text by grepping the log: `tr -d '\000' < log | grep -a "..."`
4. Language-switch verification: edit `language = en` in the throwaway config and
   re-run — UI must render in English. (Piping stdin into the TUI does NOT work;
   interactive `/lang` cannot be automated this way.)

## Pitfalls
- **tview color codes** (`[::-]`, `[::b]`, `[magenta]`) are interleaved in
  rendered text — exact-string grep patterns fail. Search short substrings only
  (e.g. `grep -c "Cambiar el idioma"`).
- **Piping stdin to a tview app doesn't work** (raw-mode terminal input) — don't
  waste turns on `printf ... | script`; verify via config changes + re-run instead.
- **adrg/xdg caches base paths on first use**: changing `XDG_CONFIG_HOME` with
  `t.Setenv` in a test after import has NO effect. In tests, assign the internal
  `configFilePath` var directly (same package) instead.
- **ini.TitleUnderscore pads keys** (`language             = en`) — assert with a
  regex (`(?m)^language\s+=\s+en$`), not exact strings.
- **ini.SaveTo does not create parent dirs** — mkdir before saving in tests.
- **Status vs message separation** in whatsmeow: see
  `references/whatsmeow-statuses.md`.
- gofmt realigns map keys — run it before building to avoid diff noise.
- **Repos on the NTFS/fuseblk mount** (`~/proyectos` → `/mnt/windows-data`):
  files can flip `644→755` and show as ` M` with 0/0 diffs — that's a
  filemode change, not content. Diagnose with `git diff --summary` (look for
  "mode change"); fix once per repo with `git config core.filemode false` +
  `git update-index --refresh`. FUSE also drops `.fuse_hidden*` temp files
  into the tree — `git add -A` WILL commit them (happened 2026-08): add
  `.fuse_hidden*` to .gitignore and scan `git status`/`git ls-files` before
  committing.
- **graphify-out/** is generated and gitignored in wash; after code changes
  refresh the stale graph with `graphify update .` (no LLM, cheap). A
  `graphify watch` started from a Hermes session dies with the session
  (becomes defunct) — don't rely on it persisting; prefer one-shot updates
  or the user running watch in their own terminal.
