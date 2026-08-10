Title: Horizontal snapping shelf carousel
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0001-bookshelf-carousel-and-create.md

## What to build

Replace the 2-up vertical grid of étagères with a horizontal, snapping carousel of larger
shelf cards. Cards are ~85% of the screen width with the next card peeking; each swipe
snaps to a card (`scrollTargetLayout` + `scrollTargetBehavior(.viewAligned)`). Shelves are
ordered A→Z. The "Étagères" title sits above the carousel; the "Tous les livres · N"
title and flat list remain below, in the page's vertical scroll. Searching still hides the
shelves and shows the flat filtered list. Each shelf card keeps its existing mixte layout
(now at the larger card width, zone height = 9/16 of card width).

## Acceptance criteria

- [ ] Shelves render in a horizontal carousel, cards ~85% width with a visible peek.
- [ ] Swiping snaps cleanly to one shelf per gesture.
- [ ] Shelves ordered alphabetically; "Étagères" and "Tous les livres · N" titles present.
- [ ] "Tous les livres" flat list stays below the carousel; tapping a row opens the book.
- [ ] Focusing search hides the carousel and shows the flat filtered list.
- [ ] Vertical space used by the shelves stays bounded regardless of shelf count.
- [ ] No UICollectionView update-loop / layout regressions.

## Blocked by

None - can start immediately.
