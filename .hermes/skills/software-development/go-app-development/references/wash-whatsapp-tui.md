# WaSh — Go WhatsApp TUI (user project at ~/proyectos/wash)

Terminal WhatsApp client (tview + whatsmeow + SQLite). Iteratively maintained with this agent; both architecture and pitfalls below were verified in session.

## Architecture map
- `main.go` — tview UI. Globals: `chatRoot`/`statusRoot`/`contactRoot` tree nodes, `textView`, `textInput`. `UiHandler` implements `messages.UiMessageHandler` (bridge: UI thread via `app.QueueUpdateDraw`).
- `messages/session_manager.go` — connection + command bus. `eventHandler.Handle(evt)` switches on whatsmeow events (`events.Message`, `events.HistorySync`, Connected/Disconnected/LoggedOut). `execCommand` handles `/commands`. All user-facing strings must go through `config.T(...)`.
- `messages/storage.go` — in-memory `MessageDatabase` (maps + mutexes): `messages` (by ChatId), `messagesById`, `chats`, `contacts`, `statuses []Message`. NOT persistent across runs (session DB is whatsmeow's sqlstore).
- `messages/messages.go` — `Message` struct (+ `IsStatus bool`), `UiMessageHandler` interface, `STATUSSUFFIX = "status@broadcast"`.
- `config/settings.go` — ini config (`~/.config/wash/wash.config`), sections general/keymap/ui/colors. `config.Save()` re-serializes. `config/i18n.go` — `T(key)` translations map es/en with fallback en → raw key; `Config.General.Language` selects (default "es").

## whatsmeow status-update handling (verified against vendored v0.0.0-2026-07-30)
- WhatsApp status updates arrive as ordinary `*events.Message` — the ONLY discriminator is `evt.Info.Type == "status"` (parsed from the node's `type` attr at whatsmeow message.go:236). There is NO `GetStatuses()` API in this version.
- Chat for incoming statuses is `status@broadcast` (`types.StatusBroadcastJID`); the real author is `info.Sender`. Contact attribution MUST use Sender, not Chat, or every status shows as the broadcast JID.
- `events.HistorySync` includes a `status@broadcast` conversation — skip `AddChat` for it and route its messages to the status store, or a fake "status@broadcast" chat appears in the chat list.
- Status revokes arrive as `ProtocolMessage` REVOKE with `protocol.GetKey().GetID()` — also remove from the status store and refresh the statuses list.
- Correct flow: detect `IsStatus` early in the live-message handler → store in a SEPARATE status store + `SetStatuses(...)`, and return BEFORE `AddMessage`/unread/notify paths.

## i18n pattern used
1. `Language` field on `config.General` (ini key `language`, default `"es"`).
2. `config.T(key)` — map[lang]map[key]string, fallback en → key.
3. Replace UI strings with `config.T("help.keys")` etc.; formatted strings keep `%s`/`%d` placeholders + `fmt.Sprintf`/`Fprintf`.
4. `/lang es|en` command in `execCommand` → mutate `Config.General.Language`, `config.Save()`, `uiHandler.RefreshLanguage()` (new interface method that re-titles the tree root nodes). Add the method to `UiMessageHandler` interface AND the main.go implementation or the build breaks.

## Verification recipe (all three passed at session end)
```bash
export PATH=$PATH:/home/madmasx/.local/go/bin
make build && go test ./... -count=1
# pty smoke (never touches real config):
timeout 8 script -qec "timeout 6 env XDG_CONFIG_HOME=/tmp/x ./wash" /dev/null 2>&1 | tr -d '\000' | grep -a -o "Contactos\|en línea"
# language flip: edit XDG config `language = en`, relaunch, grep "Contacts|online"
```

## Pitfalls hit
- `go test` with `t.Setenv("XDG_CONFIG_HOME", ...)` did NOT redirect InitConfig — adrg/xdg caches on first use; the test wrote to the real user config until the internal `configFilePath` var was assigned directly (same-package test).
- ini assertion failed on exact `"language = en"` — TitleUnderscore pads to aligned columns; regex required.
- `go run` of a scratch module with `go 1.24` in go.mod downloaded the old toolchain and refused wash's `go 1.25` requirement — set the scratch go.mod to the project's go directive.
