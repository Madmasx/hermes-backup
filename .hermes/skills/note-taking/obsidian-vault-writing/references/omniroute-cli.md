# OmniRoute CLI — Quick Reference (verified v3.8.49)

Verified against source: `bin/cli/commands/*.mjs` (serve.mjs, stop.mjs, restart.mjs,
status.mjs, doctor.mjs, providers.mjs, autostart.mjs, setup-*.mjs) and
`docs/guides/SETUP_GUIDE.md`. Re-verify with `grep -rn ".command(" bin/cli/commands/`
if the version drifts.

## Open / start

| Command | Effect |
| ------- | ------ |
| `npm run dev` | Dev server from source clone (`~/proyectos/omniroute`), foreground |
| `omniroute` | Default command = `serve`, foreground, opens browser (ASCII banner) |
| `omniroute serve --no-open` | Serve without opening browser |
| `omniroute serve --daemon` | Background daemon (does not block the terminal) |
| `omniroute autostart enable` | Start at login (aliases `on`/`true`; `disable`/`off`, `status`) |
| `npm run start` | Production build server |

Dashboard: `http://localhost:20128` · API base: `http://localhost:20128/v1`

## Close / stop

| Command | Effect |
| ------- | ------ |
| `Ctrl + C` | Stops a foreground `npm run dev` / `omniroute` |
| `omniroute stop` | Clean stop of CLI-served process (PID file; falls back to port 20128 kill) |
| `omniroute restart` | `stop` + `serve` again |
| `fuser -k 20128/tcp` | Force kill by port (Linux, unresponsive server) |
| `pkill -f omniroute` | Force kill by process name |

Note: `stop`/`restart`/`--daemon` apply to the globally-installed CLI (`omniroute`),
NOT to `npm run dev` from the repo — that one closes with Ctrl+C.

## Useful commands

| Command | Effect |
| ------- | ------ |
| `omniroute status` | Server status: version, DB, port |
| `omniroute doctor` | Health diagnostics without starting the server |
| `omniroute logs --follow` | Live usage logs |
| `omniroute setup` | Onboarding: password + first provider |
| `omniroute providers list` / `test <id>` / `test-all` | Manage/test providers |
| `omniroute config` | CLI tool config (list/get/set) |
| `omniroute update` | Check/apply updates |
| `omniroute runtime repair` | Rebuild native binaries into user-writable runtime |
| `omniroute setup-claude` / `-codex` / `-cursor` / `-cline` | Point a coding tool at OmniRoute |
| `omniroute setup-aider` / `-kilo` / `-roo` / `-goose` / `-qwen` / `-crush` / `-continue` | More tool configs (see `--help`) |
| `omniroute --mcp` | MCP server over stdio |
| `omniroute --version` / `--help` | Version / full help |

## Ports & data

- Default: port 20128 serves API + dashboard together
- Split dev ports: `PORT=20128 DASHBOARD_PORT=20129 NEXT_PUBLIC_BASE_URL=http://localhost:20129 npm run dev`
- Change port: `omniroute --port 3000` or `PORT=3000`
- Data dir: `~/.omniroute/` (SQLite, `DATA_DIR` configurable)
- Node requirement: `>=22.22.2 <23 || >=24.0.0 <27`
- Smoke test without credentials (model `auto` uses free providers):
  `curl http://localhost:20128/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"auto","messages":[{"role":"user","content":"Hola!"}]}'`

## Guía en el vault

Full user-facing guide written to `/home/madmasx/WindowsData/INFO/Guia_OmniRoute.md`
(sections: Abrir / Cerrar / Comandos útiles / Comprobar que está vivo / Notas rápidas).
