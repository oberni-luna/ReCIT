Title: Add a book to an étagère from the book's "..." menu
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0004-shelf-membership.md

## What to build

Let a user file a book onto one of their étagères from the book detail screen's existing
"..." toolbar menu. When exactly one étagère is a sensible target the menu names it outright
("Ajouter à Classiques français"); when there are several it opens a submenu of them.

The shelf updates the moment the user taps, and the write goes to inventaire.io in the
background.

**Eligibility.** The add list is the user's étagères *minus* the ones this book is already on,
so the menu never offers an action that would do nothing. The "one entry vs submenu" rule
applies to that filtered list, not the raw one. With nothing eligible — no étagères at all, or
the book is already on every one of them — there is no add entry.

**Ownership gate.** Étagères hold items (a specific copy), not editions, and the menu acts on
an edition. Both this and the removal in the next slice only appear when the current user owns
a copy; the screen already resolves that.

**The menu's contents come from a pure function** taking the user's étagères and the item's
current étagères, and returning both the add list and the remove list with their 0/1/many
shape. This slice builds the whole function and its tests, but only consumes the add half —
the next slice consumes the other. Keeping it whole avoids splitting one small module across
two issues.

**The write is optimistic** per ADR 0001: mutate and save the local relation first so the UI
answers instantly, run the call in a model-owned background task, reconcile from the response
on success, revert and surface the error through the shared reporter on failure.

**Syncs must not clobber it.** Étagère membership has two independent wholesale writers today
— the shelf sync's item-linking pass and the inventory sync's per-item shelf assignment — both
of which assign the relation outright from server state. A sync landing between an optimistic
write and its confirmation would visibly undo it. Gate syncs while a membership mutation is in
flight; the model already tracks its most recent in-flight task.

**Server contract — verify before building on it.** The endpoint takes the shelf id and a list
of item ids and returns the affected shelves keyed by id, which the existing shelves response
DTO already decodes. This was read from inventaire's last public source, **archived in May
2025**. Confirm it against the live server first. If the live contract differs, stop and
report rather than guessing — everything downstream depends on this shape.

No SwiftData schema change: the relation exists and both syncs already populate it.

## Acceptance criteria

- [ ] The `add-items` contract is confirmed against the live inventaire.io server before the implementation is finalised; a mismatch is reported rather than worked around.
- [ ] The book detail "..." menu offers an add action only when the current user owns a copy.
- [ ] With one eligible étagère, the menu shows a single entry naming it.
- [ ] With two or more eligible étagères, the menu shows a submenu listing exactly those.
- [ ] Étagères the book is already on never appear in the add list.
- [ ] A user with no étagères, or a book already on all of them, sees no add entry.
- [ ] Tapping an entry files the book and the change is visible immediately, before the network call returns.
- [ ] The book appears on that étagère's card in the carousel without a manual refresh.
- [ ] A successful write reconciles from the server's response.
- [ ] A failed write reverts the local change and surfaces the error through the shared reporter.
- [ ] A sync starting while a membership write is in flight does not undo it on screen.
- [ ] A book can be on several étagères at once.
- [ ] Unit tests cover the menu-shape function: add list excludes current membership; remove list equals current membership; 0/1/many boundaries on both; book on every shelf yields no add entry; book on none yields no remove entry; no shelves yields neither; the two lists never overlap.
- [ ] No SwiftData schema change.

## Blocked by

None - can start immediately.
