Title: The sorting surface, read-only
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

The screen that lays the whole library out as it is filed — with nothing to move yet.

Reachable from the étagères screen. On arrival it syncs shelves and inventory against the server
behind a progress indicator, then reads the store **once** into value types and never observes
SwiftData again. Every étagère is a section with its books; last comes `À ranger`, holding every
book that is on no étagère.

This is a **new screen alongside the existing auto-sort flow**, which keeps working untouched
until the slice that dismantles it.

### The frozen snapshot is deliberate

ADR 0001 binds the UI to SwiftData and keeps it reactive. This screen is a draft, not a display:
the membership gate only stands syncs down *during a write*, so across a sorting session lasting
minutes a sync triggered elsewhere would rewrite the shelf-to-item relation wholesale and move
books under the user's fingers. Say this where the snapshot is taken, so the next reader does not
"fix" it into a `@Query`.

### Pure modules

`SortSection` (an étagère, a draft, or the unshelved pile), `SortSnapshot` (the frozen library in
value types), and `SortProjection` — snapshot plus an empty change stack for now — which owns the
invariant that every book is in exactly one section.

### The foot

The three-button bar from the mockup, with the stack always empty: `Proposer un rangement` absent
for now, `Appliquer le rangement` inert, and the third button reading `Terminer`, which closes the
screen. The label rule is already the derived one — empty stack means `Terminer` — so the next
slices change nothing here.

## Acceptance criteria

- [ ] An entry point on the étagères screen opens the sorting surface
- [ ] The screen syncs before it renders, showing a progress indicator, and freezes its snapshot
      afterwards
- [ ] Every étagère of the user appears as a section with the books it holds, and the count in
      its header matches the rows under it
- [ ] `À ranger` lists every book on no étagère, sits last, and hides its genre line
- [ ] A sync landing while the screen is open moves nothing on screen
- [ ] `SortProjection` keeps every book in exactly one section, asserted without a store
- [ ] The third button reads `Terminer` and closes the screen; the apply button is inert
- [ ] Rows carry the drag handle, inert at this stage
- [ ] Copy lives in the string catalogue with `fr` and `en` values
- [ ] Renders in light and dark

## Blocked by

None - can start immediately
