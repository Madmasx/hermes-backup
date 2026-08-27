---
name: whatsmeow-development
description: Use when working on whatsmeow WhatsApp clients (wash TUI).
---

# whatsmeow Development (WhatsApp Go clients)

Working on Go WhatsApp clients built on `go.mau.fi/whatsmeow` — including the user's **wash** TUI (`/home/madmasx/proyectos/wash`, a tview-based terminal client, binaries `wash`/`whatscli`).

## Trigger Conditions
- Fixing/adding features to wash or any whatsmeow-based client (message routing, statuses, media, history sync).
- Restructuring the sidebar tree (sections, chat/group/status/contact separation) or adding new UI sections.
- Debugging why WhatsApp messages land in the wrong UI section (chats vs statuses).
- Building or verifying a Go project on this machine.

## Build / Run / Verify (wash)

```bash
export PATH=$PATH:/home/madmasx/.local/go/bin   # Go is NOT in PATH
cd /home/madmasx/proyectos/wash
make build            # → ./wash
go test ./...         # unit tests live in messages/ (storage_test, session_manager_test)
go run .              # dev run
```

- `go vet ./...` reports pre-existing unkeyed-struct-literal warnings in `main.go` — not regressions; ignore unless touching those lines.
- **TUI verification:** `wash` is a curses app with no HTTP server, so `hermes verify` readiness (HTTP probe) will always fail — that phase does not apply. Smoke-test the real binary instead:
  ```bash
  timeout 6 script -qec "timeout 4 /home/madmasx/proyectos/wash/wash" /dev/null
  ```
  A healthy boot prints the WaSh banner, "connected", contact/chat counts, and the sidebar tree (Chats / Grupos / Estados / Contactos) — no fake chats.
  To assert the tree section headers specifically (e.g. after adding/renaming a section), grep the raw pty capture with a throwaway XDG_CONFIG_HOME so the real `~/.config/wash` session is never touched:
  ```bash
  timeout 12 script -qec "env XDG_CONFIG_HOME=/tmp/wash-smoke timeout 8 ./wash" /dev/null 2>&1 | tr -d '\000' | grep -a -o "Grupos\|Chats\|Estados\|Contactos" | sort | uniq -c
  ```

## whatsmeow Event Model (essential facts)

- Incoming messages arrive as `*events.Message` via `client.AddEventHandler(...)`; `evt.Info` is a `types.MessageInfo` containing `MessageSource` (Chat, Sender, IsFromMe) plus `Type string`.
- `info.Type` is read from the XML attribute at `message.go:236` (`info.Type = ag.OptionalString("type")`).
- **Status updates (estados) are `*events.Message`** — they are NOT a separate event type. `evt.Info.Chat == types.StatusBroadcastJID` (`status@broadcast`) is the reliable marker.
- **⚠ `evt.Info.Type == "status"` is NOT reliable** (empirically verified 2026-08: live statuses leaked into chats because the type attr was not "status"). Detect via the CHAT JID, not the type attr: `isStatus := info.Type == "status" || info.Chat == types.StatusBroadcastJID || (info.Chat.User == "status" && info.Chat.Server == types.BroadcastServer)`.
- **`client.ParseWebMessage()` NEVER sets `Info.Type`** (checked in whatsmeow client.go `ParseWebMessage`: the MessageInfo it builds has no Type field) — so HistorySync messages can never be status-detected by type; rely on the conversation JID.
- `types.StatusBroadcastJID` = `status@broadcast` (`types/jid.go`). Incoming statuses have `Chat = status@broadcast` and `Sender` = the contact who posted.
- **Contact attribution:** for a normal DM, the contact is `info.Chat`; for a status, `info.Chat` is the broadcast JID, so attribute using `info.Sender` or every status shows under "status@broadcast".
- HistorySync (`*events.HistorySync`) includes a **`status@broadcast` "conversation"** holding recent statuses — it must be excluded from the chat list and its messages routed to the status store (see pattern below).
- Revokes arrive as `ProtocolMessage_REVOKE` — for statuses the key targets the status message ID.

## Status-vs-Message Separation Pattern (validated fix)

Statuses must live ONLY in a statuses list, never in chats/messages/notifications:

1. Add `IsStatus bool` to the internal `Message` struct; set it in the normalizer via the CHAT JID (see ⚠ above — do NOT rely on `info.Type` alone), and when true, derive contact fields from `info.Sender` (not `info.Chat`).
2. Keep a dedicated status store (e.g. `statuses []Message` with `AddStatus/GetStatuses/RemoveStatus` + mutex), separate from the per-chat message maps. Sort newest-first.
3. In the live-message handler, early-return statuses: `AddStatus(msg)` → refresh UI statuses list → return (no AddMessage, no unread, no notification).
4. In HistorySync: skip `chatJID == types.StatusBroadcastJID` as a chat (route its messages to the status store), AND route any message with `msg.IsStatus` to the status store even inside normal conversations. Refresh the statuses list after the sync.
5. On revoke, also `RemoveStatus(id)` and refresh.
6. **Defense in depth — storage guard:** in `AddMessage()`, re-route anything whose `ChatId` is `status@broadcast` (or `IsStatus`) to `AddStatus()` and return false. This is what actually stops the phantom-chat symptom (a leaked status creates a chat named after the first sender's pushname, e.g. `~ (7)`). Also exclude status-broadcast chats from desktop notifications (`notify()`) — the notify branch runs after AddMessage regardless of the guard.
7. UI side: the handler interface already had `SetStatuses([]Message)` and a "Estados" tree node — wire the store to it. When a status node is selected in the tree, render the status message directly (`NewScreen([]Message{ref})`) — `GetMessages(status@broadcast)` is always empty because statuses are not in the chat maps.
8. Symptom of this leak: a chat node whose name is a contact's pushname (often `~`), with unread count equal to recent statuses, all `[IMAGE]`/`[VIDEO]` entries from multiple contacts. Root cause = statuses stored with `ChatId="status@broadcast"`.

## Sidebar Tree & Section Separation (tview)

The left tree is assembled in `MakeTree()` (main.go): `mainRoot "WaSh"` → section roots `chatRoot` (Chats), `groupRoot` (Grupos), `statusRoot` (Estados), `contactRoot` (Contactos). Each section root is a package-level var so `UiHandler` methods can clear and repopulate it.

- **Adding a section** (validated 2026-08, the "Grupos" split): declare a new `*tview.TreeNode` var, create it in `MakeTree()` with `config.T("ui.<key>")` and `ListHeader` color, `mainRoot.AddChild(...)`, and give it a repopulate branch in the relevant `UiHandler` method.
- **Splitting one list across two sections**: in `SetChats([]messages.Chat)`, branch on `element.IsGroup` — groups (`@g.us`) go to `groupRoot` with `list_group` color, DMs to `chatRoot` with `list_contact` color. The selection-preservation logic (`element.Id == oldId → currentReceiver = element` and `element.Id == currentReceiver.Id → treeView.SetCurrentNode(node)`) must be duplicated inside EACH branch — it was originally hoisted after the loop and silently loses the selection once a second root exists.
- **Group nodes need no extra wiring**: groups are `messages.Chat{Id: JID, IsGroup: true}`; the existing `SetSelectedFunc` → `SetDisplayedChat(ref)` path opens them, and group commands (create/leave/subject/participants) already refresh via `SetChats(db.GetChatIds())`, which now updates both sections.
- **i18n contract for new UI strings**: every new tree header needs the key in BOTH language maps of `config/i18n.go` ("es" AND "en"), a `SetText` line in `UiHandler.RefreshLanguage()`, and a case in `config/i18n_test.go` — otherwise `/lang` leaves the new header untranslated and CI-adjacent tests miss the key.

## Pitfalls
- **Repo hygiene & privacy before git push:** the WhatsApp session DB (`session.db`, holding contacts/chats/messages) lives OUTSIDE the repo at `~/.config/wash/` (via `xdg.ConfigFile`) — before promising "your contacts are not uploaded", verify: `find ~ -maxdepth 3 -name "*.db" -path "*wash*"` and `git status --porcelain | grep -iE "\.db|session"`. After rebranding a binary (whatscli → wash), old `.gitignore` entries stop matching and the NEW binary shows up untracked (`?? wash`); update `.gitignore` with the new names (`wash`, `wash.exe`) plus a defensive `*.db*` block, then confirm with `git check-ignore wash`. When rewriting the project README, verify every claim against source first: version from `var VERSION` in main.go, command list from the `execCommand` switch + `commandNames` in messages.go, config path from `GetConfigFilePath()`, Go version from go.mod, existing screenshot filename in `doc/`. This user wants the README in Spanish, well-formatted, with a credits section crediting BOTH `@madmasx` and Hermes — he explicitly asked not to take all the credit himself.
- **Slash-command autocomplete (implemented in wash):** keep the source of truth in `messages/messages.go` (`commandNames` var + `AvailableCommands()`, documented to stay in sync with the `execCommand` switch in `session_manager.go` plus main.go's special-cased `help`/`commands`/`quit`). Route the input field's autocomplete through a dispatcher: `if strings.HasPrefix(text, cmdPrefix) → commandSuggestions` (prefix match, case-insensitive, `nil` once a space appears because args follow), else `@mention` suggestions. Reuse the SAME dispatcher in the InputCapture arrow-key bypass (`len(inputSuggestions(sndTxt)) > 0` → let arrows pass), or command navigation breaks exactly like the mention case did. Typing only the prefix (`/`) offers the full command list.
- **Clipboard image paste (screenshot → send, implemented in wash, `main.go::handlePasteUser`):** hook the existing paste keybinding; on each paste, probe the clipboard for an `image/*` target BEFORE falling back to text. X11: `xclip -selection clipboard -t TARGETS -o` lists mimes (pick first `image/...` prefix), then `xclip -selection clipboard -t image/png -o` yields raw bytes — verified byte-identical on this machine (X11 + xclip at /usr/bin/xclip, no wl-paste). Wayland: `wl-paste --list-types` + `wl-paste --type image/<t>`. Write bytes via `os.CreateTemp("", "wash-paste-*."+ext)` (map `jpeg`→`jpg`) and push `messages.Command{"sendimage", []string{path}}` — same async channel as drag & drop. If no image target, fall through to the normal text paste. Guard with the no-receiver check. Note: a clipboard probe that fails (empty clipboard) must silently fall back to text paste, not print an error.
- **@mention autocomplete & direct-chat shortcut (implemented in wash, `main.go`):** keep a package-level `contactList []messages.Contact` populated from the UI handler's `SetContacts` (contacts come from `client.Store.Contacts.GetAllContacts` → `loadContacts`). Wire `InputField.SetAutocompleteFunc(contactSuggestions)`: only suggest while typing after the last `@` with no spaces yet, return entries as the FULL resulting text (`currentText[:at+1]+name`, e.g. `hola @Juan`) because tview's autocomplete REPLACES the whole field text on select (Enter/Tab) — that preserves text before the mention. Enter with a bare `@Name` opens the direct chat (`chatForMention` → `SetDisplayedChat`); mention expansion in outgoing group messages converts `@Name` → `@<phone>` (whatsmeow mention format) via a single case-insensitive regex built from `regexp.QuoteMeta(name)` joined with `|`, which handles multi-word names. Note: this tview version consumes the first Enter to select the suggestion, so opening a chat needs a second Enter — standard tview behavior. **Arrow-key navigation pitfall:** if the input field has an `InputCapture` that intercepts Up/Down (e.g. to scroll the message history) and returns nil, the autocomplete list can never be navigated. Fix: in the capture handler, `if len(contactSuggestions(sndTxt)) > 0 { return event }` so arrows pass through while the list is open. This requires `contactSuggestions` to keep matching multi-word names (drop the "no spaces in term" guard) — otherwise the first arrow press replaces the field with the full name ("@Juan Pérez") and the list collapses. Trailing-space text ("@ju ") still returns nil naturally since no name contains the term.
- **Clickable links in messages (implemented in wash, `links.go`):** detect URLs with `https?://[^\s]+`, colorize AFTER `tview.Escape` (order matters — tags must not be escaped), open via the same `open.Run` path as the `/url` command. Left click on the exact URL span opens it; other clicks keep tview's region highlight. Requires a line index replicating tview's tag-stripping + wrap (see `go-tui-development` → `references/tview-rendering-and-click-mapping.md`). Sync rule: ALL textView writes must go through the logging helper (e.g. `tviewLine`) and the log resets on Clear/SetText or the click map silently desyncs; ANSI image/QR output logs a sentinel line. New `LinkColor` config key (default `lightblue`) + help line in both language maps.\n- **Drag & drop attachments:** TUIs can't receive native drops; modern terminals (WezTerm, kitty) insert the dropped file's absolute path as text into the focused input. Pattern (implemented in wash, `main.go::mediaCommandForPath`): in the Enter handler, before the command-prefix branch, `os.Stat()` the raw input (trim quotes/tilde); if it's a regular file, map the extension to the media command (`sendimage`/`sendvideo`/`sendaudio`/`upload`) and push `messages.Command{cmd, []string{path}}` — the existing `sendMediaCommand` handler already uses `sm.currentReceiver`, so no chat plumbing is needed. Guard with the no-receiver check.\n- **Phantom `git status` M on every file = file-mode change on the NTFS mount:** repos under /mnt/windows-data (fuseblk) show `mode change 100644 => 100755` with 0-line diffs (`git diff --summary` confirms) after anything touches file mtimes. Fix once per repo: `git config core.filemode false && git update-index --refresh`. Do NOT "fix" the permissions back — they flip again.
- A pre-existing naive implementation may "filter" statuses by substring (`strings.Contains(chatID, "broadcast")`) out of the message map — this still pollutes the per-contact chats (statuses keyed by contact JID slip through) and breaks broadcast lists. Use the explicit `info.Type == "status"` flag instead.
- Statuses must not trigger desktop notifications (`beeep`) or unread counters — filter before the notify path.
- Media statuses parse through the same message kinds (image/video/text); the kind switch in the normalizer is shared, so only routing differs.
- Never add the `status@broadcast` conversation to the chat list — it shows up as a nameless "chat" and confuses ordering.
