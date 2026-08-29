# Adding and removing books from étagères

Shipped on 2026-08-20 from PRD `docs/prd/0004-shelf-membership.md`
(issues `issues/0015-add-book-to-shelf-from-menu.md` through
`issues/0017-swipe-to-remove-in-shelf-detail.md`). No new ADR — this is ADR 0001's
optimistic pattern applied to a new domain, and ADR 0004's "membership out of scope" note
was amended rather than replaced.

## What it does

An étagère's contents stopped being read-only. From a book's "..." menu you can file it onto
one of your étagères or take it off one it is on: a single sensible target names itself
("Ajouter à Classiques français"), several open a submenu, and a target that would do nothing
is never offered. Inside an étagère, swiping a book's row takes it off that shelf.

The shelf updates as you watch; the write goes to inventaire.io behind it. Removing a book
from a shelf never removes it from your inventory, and never touches its place on other
shelves.

## Technical surface

- Screens: the book detail screen's toolbar menu, and the étagère detail screen's rows.
- **New:** `ShelfMenuOptions` — one pure function turning the user's shelves plus an item's
  shelves into both the add list and the remove list, each with its 0/1/many shape.
  `BookShelfMenu` renders them.
- `ShelfModel` gains `addItem` and `removeItem`, both optimistic, sharing one private write
  path so there is a single place in the app that posts membership.
- New payload DTO for the `{ id, items }` body; the response reuses the existing
  shelves-with-items DTO.
- `ShelfDetailView` gains a trailing swipe action.
- No SwiftData schema change — the many-to-many relation already existed and both syncs
  already populated it.

## Notable decisions

- **The server contract was verified against the live generated OpenAPI spec and the current
  source on Codeberg.** inventaire moved off GitHub; the GitHub repository is an archived
  mirror that reads as authoritative while being stale. The canonical method for these
  actions is now PUT, with POST kept as a declared legacy alias — which is why the app's
  POST calls still work, and why they will need revisiting.
- **The menu is gated on owning a copy.** Étagères hold items, not editions, and the menu
  acts on an edition; the screen already resolved the user's own copy for other purposes.
- **The add and remove lists are exact complements** over the same set, so a book on every
  shelf can only be removed and one on no shelf can only be added. No dead entries in either
  direction, by construction rather than by filtering twice.
- **Syncs stand down while a membership write is unconfirmed.** Membership has two
  independent wholesale writers — the shelf sync's linking pass and the inventory sync's
  per-item assignment — and either would have undone an optimistic write still in flight.
  The gate began as a flag and became a depth counter once the AI feature's bulk apply
  arrived.
- **Reconcile uses the response's item ids**, not just the returned metadata, so the local
  relation lands on authoritative membership. Taking the last book off a shelf can come back
  with no items key at all; that reads as an empty membership rather than as a failure.
- **The swipe is not styled as deletion** — no destructive role, no red, and a glyph that
  reads "off the stack". Red is what an iOS trailing swipe normally looks like, so this is a
  deliberate departure: nothing is being lost, and teaching people to fear a reversible
  action is the worse outcome. Full swipe stays on and is stated in code rather than left to
  its default.
- **Errors go through the shared reporter.** The equivalent swipes in the lists feature
  discard theirs with `try?`; that is a pre-existing bug this deliberately did not copy.

## Known gaps

- `ShelfModelTests` has a mock-API harness but covers only `createShelf`. Membership writes'
  reconcile and revert are untested, and that suite is where they would fit cheaply.
- A pull-to-refresh inside a write's round trip can still race the shelf sync's first pass,
  which is ungated and deletes what the server does not list. The create path has had the
  same exposure since ADR 0004.

## Issues

> The issue files listed here were deleted in the 2026-08-29 docs cleanup, once shipped.
> The paths below are the ones they had then; issues have since moved under `docs/`.
> To read them: `git log --diff-filter=D --oneline -- issues/ docs/issues/` then
> `git show <commit>^:<path>`.

- `issues/0015-add-book-to-shelf-from-menu.md` — add a book to an étagère from the book menu
- `issues/0016-remove-book-from-shelf-from-menu.md` — remove a book from an étagère
- `issues/0017-swipe-to-remove-in-shelf-detail.md` — swipe a book off the étagère being viewed
