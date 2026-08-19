# Screen — Batch Add (`57:2401`)

## Hierarchy

```
Batch Add                      393×852
├── camera feed                full bleed, edge to edge (mocked by a screenshot)
├── Frame Highlighted Book     pinned bottom, 678→852
│   └── row                    393×91, sits directly above the tab bar
│       ├── cover              48×75, inset 16 leading, 8 top
│       ├── texts              inset 76 leading
│       │   ├── Title          content400Bold, foreground/default (#f1f1f1)
│       │   └── Authors        footnote200, 30pt below the title baseline box
│       └── Circular Icon      56×56, trailing, vertically centred on the row
├── tab bar                    769→852
└── home indicator             818→852
```

Hidden in the design, deliberately: `Subtitle`, `meta` (the `Tag` and `Owner` of a normal
inventory cell).

## States drawn

Exactly one: **a book has been recognised**. Everything else is undrawn and has to be
decided during grilling:

- **Searching** — camera up, nothing recognised yet. Presumably just the bare feed.
- **Resolving** — barcode read, but the edition is still being fetched from inventaire.io.
  The network round-trip is real and the mockup shows no spinner.
- **Unknown ISBN** — a valid EAN-13 that inventaire has no edition for. Not drawn.
- **Already in inventory** — the user scans a book they already own. Not drawn, and the
  brief doesn't say whether that should be blocked, flagged, or silently duplicated.
- **Added** — what the row does after the "+" is pressed. The brief says the flow stays on
  the scanner "à la chaîne", so the row must clear or confirm somehow.
- **Camera permission denied** — not drawn.

## Interactions

- The circular "+" adds the shown book to the inventory. The flow **stays on the scanner**.
- The brief specifies **haptic feedback** "genre snackbar" when a book is found.
- No dismiss/skip control is drawn on the row.
- No explicit close control for the whole flow is drawn — the tab bar is visible, which
  muddies whether this is a modal at all.

## Assets

None to export. The camera feed is live; the mockup's screenshot (`57:2399`) is a
placeholder. The circular button's glyph is a 24pt system symbol (`plus`).

## Notes for implementation

- Colours resolve to their dark values — the row sits on a camera feed, so it must be
  mode-independent rather than following the app appearance. See `tokens.md`.
- A scrim behind the row is required for legibility over an arbitrary camera image; the
  `Overlay Bottom-Top` variable is presumably it, but resolved empty in the capture.
- `CodeScannerView` fires repeatedly while a barcode stays in frame, so the flow needs
  per-code debouncing that the existing single-shot `ScanView` never needed.
