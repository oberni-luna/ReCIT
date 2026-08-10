Title: Reliable scrub via a UIKit long-press recognizer
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0002-spine-strip-scrub-margin.md

## What to build

Make the press-and-slide scrub work reliably inside the horizontal carousel by driving it
from a `UILongPressGestureRecognizer` (min duration ~0.2s) bridged into SwiftUI as an
overlay on a shelf's books zone. The recognizer recognises simultaneously with the carousel's
scroll, so a quick swipe still scrolls. On begin it arms — disabling the carousel scroll and
firing a haptic; on change it maps the finger's x to a book (zoom highlight); on end it opens
the selected book, or cancels (doing nothing) if the finger is off the shelf. A plain tap
still opens the shelf list. The carousel scroll is always re-enabled on end/cancel so it
never gets stuck. The `location.x` + books-width + count → index (and in-bounds) mapping is a
pure function, extracted so it can be unit-tested without UIKit; mapping stays linear over
the books width.

## Acceptance criteria

- [ ] A ~0.2s press then a slide scrubs the books (zoom + haptic per book).
- [ ] A plain horizontal swipe still scrolls the carousel (scrub doesn't steal it).
- [ ] The carousel scroll freezes while a scrub is armed and re-enables on end/cancel.
- [ ] Release on a book opens it; sliding off the shelf cancels (no navigation).
- [ ] A tap (no hold) still opens the shelf list.
- [ ] Works consistently on every card; verified on a device.
- [ ] Unit tests cover the pure index mapping: edges, out-of-bounds, single book, last-book clamp.
- [ ] UIKit is used only for this recognizer bridge, nowhere else.

## Blocked by

None - can start immediately.
