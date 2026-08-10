Title: 24pt horizontal margin around books on a shelf
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0002-spine-strip-scrub-margin.md

## What to build

Inset the books on each shelf card by 24pt on the left and right so the outermost books no
longer look like they float off the plank edges. The usable book width becomes the card
width minus 48pt, and the layout's fit / split-into-pile decision uses that reduced width so
books never spill into the inset area. The plank image stays full-width; only the books zone
is inset.

## Acceptance criteria

- [ ] Books are inset ~24pt from each side of the shelf card; they sit clearly on the plank.
- [ ] The plank remains full card width.
- [ ] The all-fit vs mixed-split decision uses the reduced (card − 48pt) width — no overflow into the margin.
- [ ] Single-cover and pile layouts respect the same inset.
- [ ] No regression in the carousel or the "Tous les livres" list.

## Blocked by

None - can start immediately.
