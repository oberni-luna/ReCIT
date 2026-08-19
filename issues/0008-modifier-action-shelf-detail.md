Title: "Modifier" action in the étagère detail navigation bar
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0003-shelf-label-and-add-affordances.md

## What to build

Give the étagère detail screen a way to edit the shelf it is showing. Add a **Modifier**
action to its navigation bar, in the primary-action slot, shown with both its icon and its
title so the target is real and the purpose unambiguous. Pressing it opens the existing
étagère form, prefilled with that shelf, as a sheet the detail screen owns.

The action must be absent whenever the étagère does not resolve — the detail screen looks
its shelf up by id and gets an optional back, and an ungated button would open a form that
silently behaves as a *create* for a deleted or not-yet-synced shelf.

Deliberately **not** the confirmation-action slot: that slot means "Done/Save" for a modal
and renders prominent, which is the wrong weight for a secondary action on a pushed screen.

This slice is purely additive. The pencil on the carousel card keeps working; it is removed
in a later slice, which is why this one lands first.

## Acceptance criteria

- [ ] The étagère detail screen shows a "Modifier" action in its navigation bar, trailing.
- [ ] The action uses the primary-action placement, not the confirmation-action placement.
- [ ] The action shows its title alongside its icon, not icon-only.
- [ ] Pressing it presents the étagère form prefilled with that shelf's name, description and visibility.
- [ ] Saving from that form updates the shelf, and the detail screen's title reflects a renamed shelf without a manual refresh.
- [ ] The action is not shown when the shelf id resolves to nothing.
- [ ] The carousel card's pencil still works — nothing is removed in this slice.
- [ ] The label is French, matching the rest of the app.

## Blocked by

None - can start immediately.
