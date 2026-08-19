Title: Swipe a book off the étagère being viewed
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0004-shelf-membership.md

## What to build

Inside an étagère's detail screen, swiping a book's row offers to take it off *that* shelf.
Tidying a shelf becomes a gesture instead of a trip through the book screen's menu.

It calls the same optimistic removal built in issue 0016 — no new write path.

**It must not look like deletion.** The book stays in the inventory; only its membership of
this shelf changes. So:

- The icon says "off the stack", not "trash". A bin glyph tells the user their book is about
  to be destroyed, which is false.
- **No destructive role and no red.** Red is the universal "you are losing data" signal, and
  here nobody is. Trailing-swipe-red is also just what removal looks like on iOS, so this is a
  deliberate departure — but training users to fear a reversible, one-tap-recoverable action
  is the worse outcome.
- **Full swipe stays enabled.** The action is cheap and reversible, and clearing several books
  off a shelf should be quick. (If it were destructive this would be the opposite call.)

**Errors surface through the shared error reporter**, not swallowed. The comparable swipe
actions in the lists feature discard theirs with `try?`, which is a pre-existing bug — do not
copy it. Fixing those is worth its own issue and is not in scope here.

## Acceptance criteria

- [ ] Swiping a book's row in an étagère's detail screen reveals a remove action.
- [ ] The action's label and icon make clear the book is leaving the shelf, not being deleted.
- [ ] The action is not red and carries no destructive role.
- [ ] A full swipe completes the removal without a second tap.
- [ ] The book disappears from the shelf immediately, before the network call returns.
- [ ] The book remains in the inventory and on any other étagères it belongs to.
- [ ] A failed removal restores the row and surfaces the error through the shared reporter.
- [ ] The removal goes through the same optimistic path as the menu action, not a second implementation.
- [ ] The lists feature's error-swallowing swipes are left untouched.

## Blocked by

- issues/0016-remove-book-from-shelf-from-menu.md — builds the removal write this slice calls.
