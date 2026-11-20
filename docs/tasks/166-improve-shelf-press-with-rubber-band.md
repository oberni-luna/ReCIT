---
issue: 166
status: todo
wiki: [[features/0004-shelf-press-selection]], [[adr/0006-shelf-press-selection-scrim]]
note: Sur l'étagère, en mode sélection, le livre grandi suit légèrement le doigt, comme accroché par un élastique à sa place. Vidéo de référence montrée pendant le grill (mode sélection actuel, 8,7 s).
created: 2026-11-20
---

## Context / Decisions

> Sur l'étagère, pendant le press-and-hold (feature 0004), le livre sélectionné se déplace légèrement en suivant le doigt, dans une certaine limite, comme accroché par un élastique à sa position d'origine.

Today, in selection mode, the grown copy of the pressed book sits still at its place on the shelf (`ShelfFocusOverlayView.book(_:)`). The finger picks books, nothing follows it.

- **What pulls the book**: the gap between the finger and the centre of the book at rest, per axis. Each book has its own anchor. Not the finger's travel since the press: momentum would carry from one book to the next.
- **Rubber band**: `offset = cap × gap / (cap + |gap|)` per axis. Small gaps follow almost 1:1, large ones tend to the cap.
- **Cap per axis**: `min(20 pt, (growth − 1) / 2 × book size on that axis)`. The copy (×2) is drawn over the shelf's own book, which shows through the half-strength veil: past that limit the copy would uncover it and the book would read double. A 25 × 150 standing spine → x ≤ 12.5, y ≤ 20.
- **When**: only once selection mode is armed. Before that, `ShelfPressRecognizer` gives up past 10 pt (`slop`) and the carousel scrolls, so there is nothing to follow.
- **Motion**: a short spring, around `.interactiveSpring(response: 0.2, dampingFraction: 0.7)`, so the book trails the finger slightly. Tunable constant.
  - Finger moves → pull springs to `rubberBand(gap)`.
  - Finger moves to another book → pull reset to zero without animation (the swap stays unanimated, feature 0004), then springs to the new book's pull.
  - Finger leaves the shelf → pull springs back to zero alongside the selection mode unwinding.
  - Finger lifts on a book → `focus.reset()` as today, nothing animates.
- **Reduce Motion** on → no follow, the book stays at its place.
- **Scope**: iOS only (Android has no press-and-hold on shelves). My étagères and a friend's alike, since both go through `ShelfRowView`. The cell at the top of the screen does not move.
- **Where**: the rubber-band maths in a pure, unit-tested type in `Features/Shelves/` (no SwiftUI), the pull as a field on `ShelfFocusModel`, applied as an offset on the copy in `ShelfFocusOverlayView`, computed in `ShelfRowView` from the moves it already receives. No new UIKit.

## Acceptance criteria

- Selection mode armed, finger slid a little off the book's centre → the grown book moves towards the finger, then stops moving past a limit while the finger keeps going.
- Finger on a thin standing spine, moved sideways far → the shelf's own book never shows beside the grown copy.
- Finger moved quickly then held still → the book catches up with a slight lag and settles without visible oscillation.
- Finger slid onto another book → the new book appears at its place, then leans towards the finger; the previous one does not carry over its offset.
- Finger slid off the shelf → the book returns to its place while selection mode unwinds.
- Lift on a book → the Fiche livre opens, no book left floating over it.
- Quick tap and press released before arming → no movement, same as today.
- Réduire les animations on → the grown book stays at its place whatever the finger does.
- A friend's étagère → same behaviour.
- Unit tests: rubber band is 0 at gap 0, monotonic, symmetric, never exceeds the cap; the cap is min(20, half the extra growth) per axis.
