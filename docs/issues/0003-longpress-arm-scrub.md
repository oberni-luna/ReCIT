Title: Long-press-armed scrub coexisting with carousel scroll
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0001-bookshelf-carousel-and-create.md

## What to build

Rework the shelf-card gesture so scrub and the horizontal carousel scroll no longer
conflict. A plain horizontal swipe scrolls the carousel. A short long-press (~0.2s)
sequenced before a drag arms the scrub: sliding across the books highlights each with a
zoom + `.selection` haptic; releasing on a book opens it; sliding off the shelf cancels
the selection and does nothing on release. A plain tap opens the shelf's list. Replaces
`ShelfRowView`'s bare `DragGesture` with `LongPressGesture(minimumDuration: 0.2)
.sequenced(before: DragGesture)`.

## Acceptance criteria

- [ ] Plain horizontal swipe scrolls the carousel (no scrub).
- [ ] Long-press then drag arms and drives the scrub (zoom + haptic per book).
- [ ] Release on a book pushes that book's detail; release off a shelf does nothing.
- [ ] Sliding out of the shelf bounds during a scrub cancels the selection.
- [ ] Tap still opens the shelf's list.
- [ ] Verified on a device (gesture arbitration inside a snapping scroll view).

## Blocked by

- #0002 (Horizontal snapping shelf carousel)
