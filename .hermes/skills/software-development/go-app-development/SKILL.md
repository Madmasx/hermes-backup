---
name: go-app-development
description: Use when building, testing, or verifying Go CLI/TUI apps.
---

# Go App Development

## Trigger Conditions
- Building, testing, or fixing a Go project (any module in ~/proyectos or elsewhere).
- Writing Go unit tests that touch config files, XDG paths, or ini/toml persistence.
- Verifying a Go CLI/TUI app headlessly (no display, no interactive terminal).

## Key Procedures

### 1. Toolchain Discovery (this machine)
- The user's Go is NOT in PATH: `export PATH=$PATH:/home/madmasx/.local/go/bin` (persists per session).
- `go.mod` may require a newer Go than installed (e.g. `go 1.25.0` vs 1.23.6). Go auto-downloads the matching toolchain — do NOT force `GOTOOLCHAIN=local` unless you want a hard version error.
- Verify a version requirement conflict quickly with: `go build ./...` — the first run downloads the toolchain silently.

### 2. Build & Test
```bash
make build            # if Makefile exists (canonical per repo)
go build ./...        # full compile check
go test ./... -count=1   # -count=1 avoids stale cache in "verification evidence" runs
```
- `go vet` may flag pre-existing warnings in files you did not touch (e.g. unkeyed struct literals) — those are NOT your regression; build + tests are the gate.

### 3. Verifying TUI/CLI Projects Headlessly
- `hermes verify --json` reports `overall: false` for TUI/CLI projects because its readiness phase probes an HTTP port. build/test/make-build phases still pass — treat those as the evidence, and compensate for readiness with a pty smoke test:
  ```bash
  timeout 8 script -qec "timeout 6 ./app" /dev/null 2>&1 | tr -d '\000' | grep -a -o "expected text 1\|expected text 2"
  ```
- Use a throwaway config home so smoke runs never touch the user's real config:
  `env XDG_CONFIG_HOME=/tmp/xxx ./app` (works in a fresh process; see pitfall on xdg caching).
- **Piped keystrokes (`printf | script -qec`) are NOT reliably delivered to a raw-mode TUI** (tview etc.). To verify interactive/config-driven behavior, write the config file the way the app would, then relaunch and grep the rendered output. Do not burn time scripting keystrokes into a TUI.

## Pitfalls (Go testing)

- **adrg/xdg caches base paths on first use** (sync.Once). `t.Setenv("XDG_CONFIG_HOME", tmp)` has NO effect once the package has resolved a path — tests then write to the real user config. Fix: set the env var before the first xdg call, or (same-package tests) assign the package's internal path variable directly.
- **gopkg.in/ini.v1 `TitleUnderscore` pads output** (`language             = en`, aligned columns). Assert with a regex (`(?m)^language\s+=\s+en$`), never exact `"key = value"` string containment.
- ini `SaveTo` does NOT create parent directories — mkdir them in tests (in real apps, xdg.ConfigFile creates them).
- Config writers that re-serialize on every `Save()` can overwrite user's real config in tests — always redirect the path.
- **Repos on the /mnt/windows-data NTFS mount (fuseblk) show EVERY file as `M` with 0 insertions/deletions** — it is a file MODE change (100644→100755; `git diff --summary` prints "mode change"). Caused by the mount, not by edits; don't try to restore permissions (they flip back). Fix once per repo: `git config core.filemode false && git update-index --refresh`.

## References
- `references/wash-whatsapp-tui.md` — WaSh (user's Go WhatsApp TUI): architecture map, whatsmeow status-update handling, i18n pattern, verification recipe.
