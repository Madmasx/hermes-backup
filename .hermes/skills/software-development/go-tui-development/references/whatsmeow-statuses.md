# whatsmeow: Status vs Chat Separation

Verified against `go.mau.fi/whatsmeow@v0.0.0-20260730092514-662ad1dc6900`.

## Root cause of the wash bug
WhatsApp status (story) updates arrive as `*events.Message` with
`info.Type == "status"` (set from the XML `type` attr in whatsmeow's
`message.go`). The chat JID is `types.StatusBroadcastJID`
(`status@broadcast`). Without a filter, wash treated them as normal
chat messages — they appeared in Chats and never in the Estados tree.

## Detection
```go
isStatus := info.Type == "status"
// also: info.Chat == types.StatusBroadcastJID
```

## Correct handling
1. Mark the message with `IsStatus: true` in the Message struct.
2. Store in a separate statuses slice (`db.AddStatus`), NOT via `AddMessage`.
3. Never call `SetChats` / never notify for statuses.
4. Call `uiHandler.SetStatuses(db.GetStatuses())` after every status add/remove.
5. In HistorySync: if `chatJID == types.StatusBroadcastJID`, route all of its
   messages into AddStatus and `continue` (do not create a chat entry).
6. Contact attribution for statuses: use `info.Sender` (not `info.Chat`, which
   is the broadcast JID) so the list shows the right person.

## whatsmeow notes
- There is no `Client.GetStatuses()` — statuses arrive only live and via
  HistorySync.
- `GetStatusPrivacy` is for *outgoing* privacy settings, not for listing
  other people's statuses.
- `info.Type` is set at `message.go:236` via `ag.OptionalString("type")`.
