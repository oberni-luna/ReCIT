Title: Deleting a list leaves you looking at its empty shell
Labels: needs-triage, bug
Type: AFK

## Parent

Feature: docs/features/ — the lists feature has no doc; `ReCIT_iOS/Features/Lists/EntityListDetail.swift` is the source.

## What to build

Open a list, edit it, delete it. The form dismisses and the screen underneath stays — showing
« Cette liste est vide ». The list is gone from the server and from the store, and the user is
left on its remains until they press back.

`EntityListDetail` renders `ContentUnavailableView("list.empty")` whenever it cannot find its
list. That branch was written for a list with no items; a deleted list falls into it too, so
the same screen now means two different things, and one of them is a lie.

**The deletion should return to the list of lists.** Not "when the user presses back" — at once,
as the consequence of the action they took.

## The shape this belongs to

This is the same defect as `issues/0065-crash-deleting-an-item-from-the-book-screen.md`: a
screen that outlives the object it was drawn from. Worth fixing with the same reflex in both —
the screen that owns an object is responsible for leaving when that object goes — rather than
inventing two different mechanisms a fortnight apart.

Do not conflate the two states while fixing it: a list that genuinely holds nothing must still
say « Cette liste est vide » and stay open.

## Acceptance criteria

- [ ] Deleting a list from its own screen returns to the list of lists
- [ ] A list that is simply empty still shows « Cette liste est vide » and does not pop
- [ ] Deleting from the swipe action on the list of lists behaves as before
- [ ] A list deleted elsewhere — another device, a sync — does not leave a stale screen open
      either, or it is written down why that case is left alone
- [ ] No flash of the empty state on the way out

## Blocked by

None - can start immediately
