# tview internals: click→text mapping and deterministic UI tests

Verified against tview v0.0.0-20210608105643 (the version pinned in wash's
go.mod, June 2021) and tcell v2.3.11. Re-verify the regexes/APIs if tview is
ever upgraded — this pin has NO `SetRegionClickedFunc` and TextView gets mouse
capture only via the Box-level `SetMouseCapture`.

## Goal pattern
Make a region/URL inside a tview TextView clickable. tview exposes no
hit-testing: region bounds (`regionInfos`: FromX/FromY/ToX/ToY) are
unexported. Working approach: replicate tview's rendering (tag stripping +
word wrap) in your own line index, and hook the mouse capture.

## Mouse dispatch (how a click reaches your code)
- Application.fireMouseActions → root primitive (Grid) MouseHandler → Grid
  iterates items in order; the first handler that returns `consumed` wins.
- Each primitive's handler is `WrapMouseHandler(...)`: the capture set with
  `SetMouseCapture` runs FIRST — before the primitive's own InRect check.
- Capture returning a `nil` event swallows the click; returning it unchanged
  keeps default behavior (TextView's default left-click = highlight the region
  under the cursor → `GetHighlights()`, plus setFocus).
- So: install `textView.SetMouseCapture(...)`, check `textView.InRect(x,y)`
  yourself, map to content coords, look up the index, open the link — then
  return the event unchanged so region selection still works.

## Coordinate mapping
- Content origin = rect origin for a TextView without its own border (Grid
  borders are drawn around cells; the item rect is already inset).
- contentRow = eventY - rectY + scrollRow; `GetScrollOffset()` returns
  (lineOffset, columnOffset); columnOffset is 0 when wrap is on.
- Wrap width = `GetInnerRect()` width; rebuild the index lazily on click,
  keyed by that width (invalidates on resize).

## Replicating the render (must match tview exactly)
`decomposeString` (util.go) strips tags before measuring. Regexes, verbatim:

```
colorPattern   = \[([a-zA-Z]+|#[0-9a-zA-Z]{6}|\-)?(:([a-zA-Z]+|#[0-9a-zA-Z]{6}|\-)?(:([lbdru]+|\-)?)?)?\]
regionPattern  = \["([a-zA-Z0-9_,;: \-\.]*)"\]
escapePattern  = \[([a-zA-Z0-9_,;: \-\."#]+)\[(\[*)\]
boundaryPattern= (([,\-\.:;!\?&#+]|\n)[ \t\f\r]*|([ \t\f\r]+))
spacePattern   = \s+
```

- Stripping rules: color tags of length 2 (`[]`) are filtered out and print
  LITERALLY; region tags removed; escape tags → keep `text[from:end-2] + "]"`.
- `tview.Escape` = nonEscapePattern.ReplaceAllString(text, "$1[]") → produces
  `[brackets[]` which renders as `[brackets]`. `[[]` is NOT an escape (prints
  literally). `[]` prints literally. Do not "fix" these in your stripper.
- Wrap loop (reindexBuffer, wordWrap on): loop { extract =
  runewidth.Truncate(str, width, ""); if empty → one grapheme via uniseg; if
  wordWrap && extract<str: annex leading spaces of the remainder (spacePattern),
  then split at the LAST boundaryPattern match inside extract }. Boundary chars
  (spaces/punct) STAY on the current line: wrapped lines carry trailing spaces
  and may exceed width by a few cells. Test expectations must match that.
- Column math: `runewidth.StringWidth` (wide runes/emoji).

## Line-log pattern (keep the index in sync with the buffer)
- Mirror every write: route Fprintln-style writes through a helper that logs
  the line. SetText = Clear + Write semantics: tabs → 4 spaces, split on \n,
  and the FIRST segment MERGES into the last existing buffer line; a trailing
  \n yields a trailing empty buffer line (log it too).
- Reset the log on every `textView.Clear()`.
- Unknown-line-count ANSI output (image renderers, QR code) → log a sentinel
  entry; the index is no longer authoritative below it.
- All mutations happen on the app goroutine (QueueUpdateDraw callbacks / mouse
  events) → no locking needed.

## URL span mapping
- Find URLs in the FULL stripped text (`https?://[^\s]+`), then intersect each
  match's [start,end) byte range with each wrapped line's [pos,pos+len(line))
  range; clickable columns = StringWidth(prefix..fragment). This handles URLs
  split across wrap lines (clicking either fragment opens the URL).
- tview's region model does NOT support nested regions cleanly (a URL region
  inside a message region corrupts the parent's bounds) — keep ONE region per
  message and do URL hit-testing yourself.

## Deterministic tests without an Application loop
- `screen := tcell.NewSimulationScreen("UTF-8"); screen.Init(); screen.SetSize(w,h)`
- CRITICAL: SimulationScreen is double-buffered — SetContent writes to
  `s.back`, GetContents reads `s.front`. You MUST call `screen.Show()` after
  `tv.Draw(screen)`, or the dump is blank (debugged 2026-08: empty rows).
- tcell v2.3.11 SimulationScreen has no GetSize — use
  `GetContents() (cells []SimCell, w, h int)` for dimensions.
- Simulate clicks WITHOUT an Application:
  `tv.MouseHandler()(tview.MouseLeftClick, tcell.NewEventMouse(x, y, tcell.Button1, 0), func(p tview.Primitive){})`
  — runs capture + default handler synchronously; assert on side effects (a
  package-var `linkOpen` hook the capture calls) and `tv.GetHighlights()`.
- Tests must replicate the app's write path (SetText + log append): calling
  SetText directly bypasses the log and leaves the index empty.
