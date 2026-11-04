# A book of « Tous les livres » lifts as a card on a long press

Shipped on 2026-10-31. No PRD and no issues: one slice, decided in an autopilot run whose decision log is
summarised below.

## What it does

A long press on a book opens its menu everywhere a list of books shows one — the « … » menu of the book screen,
carried by `InventoryCell` through `BookActions`. On a friend's inventory the row came
out of the page as a white card with margins and rounded corners, the menu above it. Under the étagères, in
« Tous les livres », the same press lifted nothing that could be seen: the menu opened over the page and the row
stayed as it was.

The difference was the container. A friend's inventory is a `List`: a cell lends the context menu's preview its
own margins, ground and corners. « Tous les livres » is a `LazyVStack` under the étagère carousel, and the menu sat
on the cell's bare `HStack` — the preview was the text flush against the cover, without margins, on a ground the
white page shares.

The row of « Tous les livres » now **lifts as a card**: its margins, the page's ground under it, corners rounded at
12 pt.

## Technical surface

- **`InventoryCell.standsAlone`** (default `false`) — set where the row is not a `List` cell. The cell then wraps
  its content in **`StandAloneCard`** (`Features/Inventory/`) before `.bookActions` is attached: horizontal
  `medium` and vertical `small` padding, full width, `backgroundDefault`, and
  `.contentShape(.contextMenuPreview, .rect(cornerRadius: .rounded))`.
- **`ShelvesContent.bookLink`** passes `standsAlone: true` and drops the padding and frame it used to add around the
  cell, which have moved inside it. Both column layouts go through `bookLink`.

## Notable decisions

- **The margins move into the cell rather than the menu out of it.** The menu is the cell's, on every screen; only
  the preview needed the margins, and a context menu's preview is the view it is attached to.
- **`backgroundDefault` under the row.** It is `gray/0` / `gray/1000`, white and black, the page's own ground, so the
  row looks the same at rest and the card only shows once the page behind it is dimmed.
- **The `List` call sites are unchanged** — the étagère's screen, Recherche, « Chez mes amis », a friend's
  inventory: their cells already do this.

## Not done, not verified

- Built for the iPhone 17 simulator. Not seen running: the simulator was signed out, and no password was typed. The
  long press, in light and in dark, is still to be looked at.
- No unit test: the change is rendering only.
- The end-to-end scenario was not run.
- Android not touched.
