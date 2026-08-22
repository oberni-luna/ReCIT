## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

An étagère opened as it **will be**, not as the server holds it.

Tapping a card pushes a new screen rendered from the session's projection: the books the
étagère holds plus the ones this session filed into it, in pile order — the top of the pile
first, so the card and the screen agree. A draft étagère opens too, which is why
`ShelfDetailView` cannot serve: it looks its subject up by server `_id` with a `@Query`, and a
draft has none. Its swipe is also an immediate optimistic write, which this screen must not
do.

- **Swipe to take a book off**, trailing edge, full swipe: it records a move into « à
  ranger » and nothing else. No server call, no inventory deletion. The user stays on the
  screen.
- The copy names the étagère, and the action is **neither red nor destructive** — nothing is
  deleted, the copy stays in the inventory and on every other étagère, and red would teach
  fear of an action that costs one tap to undo. Same wording and icon as the inventory's own
  remove-from-shelf.
- The title is the section's name as the projection gives it — a server étagère's name and a
  draft's name are the same kind of name.
- An emptied étagère shows the existing "this étagère is empty" line.
- If the section disappears under the screen — an apply lands it, or the stack is discarded
  elsewhere, both possible since the session is app-scoped — the screen pops.
- The pile order shown here is the same derivation as the card's, so no second ordering rule
  exists.
- Nothing can be swiped while an apply or a proposal is in flight.

## Acceptance criteria

- [ ] Tapping an étagère card pushes a screen listing what that étagère will hold, pending
      books included, in the same order as the card's pile.
- [ ] A draft étagère created this session opens and lists its books.
- [ ] Swiping a row takes the book off the étagère, keeps the user on the screen, and the book
      reappears among the books to file.
- [ ] That swipe writes nothing to the server, and the change joins the pending stack — the
      recap and the count follow.
- [ ] The swipe action is not red and not destructive, and names the étagère.
- [ ] An étagère emptied this way shows the empty line rather than a blank list.
- [ ] The screen pops if its section stops existing.
- [ ] Nothing can be swiped off while a run is in flight.

## Blocked by

- `issues/0046-grid-sorting-surface-read-only.md`
