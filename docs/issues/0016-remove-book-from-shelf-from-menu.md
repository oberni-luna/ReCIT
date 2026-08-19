Title: Remove a book from an étagère from the book's "..." menu
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0004-shelf-membership.md

## What to build

The mirror of the add action: from the book detail screen's "..." menu, take a book off one of
the étagères it currently sits on. One étagère → a single entry naming it ("Retirer de
Classiques français"); several → a submenu of just those; none → no entry at all.

The list is driven by the book's current membership, which the menu-shape function built in
issue 0015 already returns — this slice consumes the half that issue left unused. No new
filtering logic, and no new tests beyond what 0015 already covers.

**The book stays in the inventory.** Removing it from an étagère changes membership only. Its
membership of *other* étagères is untouched — one removal never cascades.

Same write discipline as the add: optimistic local mutation, background call, reconcile from
the response on success, revert and report through the shared reporter on failure, and syncs
gated while the write is in flight.

Because the add and remove lists are complements over the same set, a book on every étagère
now shows only a remove entry and a book on none shows only an add entry. No dead entries in
either direction.

## Acceptance criteria

- [ ] The `remove-items` contract is confirmed against the live server alongside `add-items`.
- [ ] The menu offers a remove action only when the current user owns a copy and the book is on at least one étagère.
- [ ] With the book on one étagère, the menu shows a single entry naming it.
- [ ] With the book on several, the menu shows a submenu listing exactly those.
- [ ] With the book on none, there is no remove entry.
- [ ] Removing takes the book off that étagère and leaves it on any others.
- [ ] The book remains in the inventory after removal.
- [ ] The change is visible immediately, before the network call returns.
- [ ] The étagère's carousel card updates without a manual refresh.
- [ ] A failed write reverts the local change and surfaces the error through the shared reporter.
- [ ] A sync starting while the write is in flight does not undo it.
- [ ] The add and remove lists never both offer the same étagère.

## Blocked by

- issues/0015-add-book-to-shelf-from-menu.md — builds the shared menu-shape function and the optimistic write plumbing this slice reuses.
