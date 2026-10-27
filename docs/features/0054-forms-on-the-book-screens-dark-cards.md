# 0054 — Forms on the book screen's dark cards, through `background/shade`

Shipped on 2026-10-27, in one commit, on autopilot: no PRD, no issues. The request was the owner's,
from a dark-mode screenshot of the book screen: forms in dark did not suit, they should look like
« Book ». The owner then added a variable to Figma, `background/shade`, as the fill of a form's
card, and asked for it in code.

## What it does

**In dark, a form's cards sit a step below its ground**, as the book screen's do: a `gray/800`
ground, cards darkened to about `#191919` by a veil of black at 40 %. They used to be `gray/800`
cards on black. Every `DesignSystem.Form` (the thirteen forms of the app) and every
`DesignSystem.FormList` (the six lists pushed from a form) changes at once.

**The book screen keeps its look, on the same two tokens.** It used to read `backgroundSecondary`
and leave its cards to the system's grouped-cell grey; it now reads `backgroundForm` and
`backgroundFormCell`, so the book and the « Modifier l'édition » form it opens are one surface. The
placeholder shown while a book resolves takes them too.

In light, nothing changes: `gray/50` ground, white cards.

## Technical surface

- **`DesignSystem.Color.backgroundShade`** — new. `.black.opacity(0)` in light,
  `.black.opacity(0.4)` in dark: Figma's `background/shade` (`784:14830`), which aliases
  `color/black-04` in dark and is transparent in light. The sixth veil of `Color.swift`.
- **`.backgroundForm`** — dark goes from `gray/1000` to `gray/800`.
- **`.backgroundFormCell`** — dark goes from `gray/800` to the shade's veil, spelled out
  (`.black.opacity(0.4)`) rather than read from `.backgroundShade`: a dynamic colour nested in
  another does not resolve, which is why the pair already named colorsets instead of aliasing.
- **`BookDetailView`** — the list's sections wrapped in a `Group` carrying
  `.listRowBackground(.backgroundFormCell)`; `.applyListBackground(.backgroundForm)`.
- **`BookResolvingView`** — the same two tokens on its one row and its list.

## Notable decisions

- **The card is a veil, not a grey**, because Figma made it one. Over `gray/800` it resolves to the
  same `#191919` as `gray/900`, so nothing a screenshot shows tells the two apart; on another ground
  the veil would darken it instead of drawing a fixed grey.
- **The cards are named, not left to the system.** The system's cell grey rises to `#2C2C2E` in a
  sheet, nearly the ground's `gray/800`, which is what had made the forms swap to black in the
  first place.
- **Figma was not written to.** The variable is the owner's; what it still lacks is recorded as
  D-FF3 in `docs/design-system/figma-library.md`.

## Owed, and known

- **Seen on the iPhone 17 simulator**, signed in: « Create new list » in light and dark, the book
  screen in dark. « Modifier l'édition », the scanner's « Nouvelle édition » and the pushed pickers
  not looked at.
- **A swipe on a translucent card not looked at.** `Form / Swipe Row` (a work detached from an
  edition with a swipe) now slides over a card that lets through what is behind it; whether the
  swipe's action shows through is unseen.
- **`scripts/e2e.sh` not run.** No accessibility identifier moved.
- **Figma** — D-FF3: `background/shade` is scoped `ALL_SCOPES` and has no description, and the
  descriptions of `background/form` and `background/form-cell` still name their old dark values.
- **Android** (`Recit_Android/`) not touched.
