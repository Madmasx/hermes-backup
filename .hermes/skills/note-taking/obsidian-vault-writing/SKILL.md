---
name: obsidian-vault-writing
description: Write notes/guides into the user's Obsidian vault.
platforms: [linux, macos, windows]
---

# User Obsidian Vault — Writing Conventions

Write and update notes in the user's Obsidian vault following their conventions.
Read the vault structure BEFORE writing anything: list `*.md` under the vault,
then read one sibling note to mirror its format.

## Vault path

- Vault root: `/home/madmasx/WindowsData/INFO` (same files resolve as `/mnt/windows-data/INFO`)
- Tool guides live in the `Guias/` subfolder, named `Guia_<Tool>.md` (e.g. `Guias/Guia_WezTerm_Comandos.md`, `Guias/Guia_Yazi_Personalizacion.md`)

## Layout map (verified 2026-08)

- Root-level special files: `Recordatorios.md` (reminders/tasks)
- Subfolders: `Guias/` (tool guides), `Finanzas/` (market reports → `Finanzas_Mercado.md`), `Juegos/` (WoW → `WOW.md`), `Proyectos/`, `Empresas/<company>/`, `Programacion/`, `Diseno_y_3D/`, `Hermes/`, `Clippings/`

## Content style

- Write content in **Spanish** (latinoamericano) unless the user asks otherwise
- Format: `# Title`, numbered sections `## N. Título`, tables for commands/options, bold inline keys (`**Ctrl + C**`, `**npm run dev**`)
- Keep it practical and concise — operational quick-reference, not comprehensive docs

## User preference (corrected in session)

When the user asks for a "guía" of a tool they already use, they want a SHORT
terminal-ops quick reference: **how to open it, how to close it, and useful
commands** — nothing more. A full setup/installation doc gets rejected and
rewritten. Default to the ops scope; only add broader sections if asked.

## Workflow

1. List `*.md` in the vault to find sibling guides / target file
2. Read a sibling guide to mirror its format
3. Verify every command, flag, and fact against the source before writing
   (project docs + `grep` the code — never document from memory; the
   omniroute repo AGENTS.md enforces this with `check:fabricated-docs`)
4. `write_file` the new note; prefer `patch` for anchored appends to existing notes

## Pitfalls

- Writing a comprehensive setup guide when the user wanted a quick ops reference
  (happened 2026-08: first version had full install docs; user asked for only
  terminal open/close + commands — rewritten)
- Inventing CLI commands: verify against the authoritative source before documenting; a command that doesn't exist in code is never documented. For a project CLI, grep the repo (`bin/cli/commands/*.mjs` or equivalent). For a terminal tool (yazi, etc.), the source of truth for default keybindings/commands is the tool's official default config on GitHub — fetch it at a pinned release tag (e.g. `curl -fsSL https://raw.githubusercontent.com/sxyazi/yazi/v26.5.6/yazi-config/preset/keymap-default.toml`) rather than documenting from memory.

## References

- `references/omniroute-cli.md` — verified OmniRoute CLI quick-reference (start/stop/commands), sourced from the repo at v3.8.49
