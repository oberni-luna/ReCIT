## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

Creating an étagère at the point where the need is discovered, and filling it in the same
movement.

- A **« + Nouvelle étagère » tile as the last cell** of the grid, same size as a card. The
  nav bar's « + » is **removed**: one action, one control, at the place it is used.
- An empty grid is that tile alone — which is also the screen's empty state, so no separate
  one is drawn or maintained.
- **The tile is a drop target.** Dropping a book on it opens the create form; confirming
  creates the étagère *and* files the book into it. Cancelling the form leaves **no trace** —
  no étagère, no move, the book never left the carousel.
- One model call does both: `createShelf(named:filling:)` replaces `createShelf(named:)`, so
  one set of guards (busy, empty name, duplicate name) protects both changes. Two calls would
  let a caller file a book into a draft that was refused, which the projection would silently
  ignore.
- The name rule is unchanged: a name already borne by an étagère **or** a draft is refused
  while the user is still in the field. A duplicate is not quietly re-routed into its
  homonym — the gesture said "new".
- After creating: **scroll to the new card first, then bounce the book in.** A bounce played
  off-screen is a bounce lost, and it is the only confirmation that the book went in.

## Acceptance criteria

- [ ] The last cell of the grid is a « + Nouvelle étagère » tile, and the nav bar has no « + ».
- [ ] A user with no étagère sees the tile alone and can create one from it.
- [ ] Tapping the tile opens the create form; confirming adds an empty card at the end of the
      grid and scrolls to it.
- [ ] Dropping a book on the tile opens the form, and confirming creates the étagère with that
      book on it.
- [ ] Cancelling that form leaves the stack exactly as it was, with the book still to file.
- [ ] A name already used by an étagère or a draft is refused in the form.
- [ ] `createShelf(named:filling:)` appends nothing on a refused name, exactly two changes on
      an accepted one, and nothing at all while a run is in flight — covered by tests.
- [ ] The scroll happens before the bounce.

## Blocked by

- `issues/0047-drag-a-book-between-sections.md`
