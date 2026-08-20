Title: Creating an étagère without leaving the sorting surface
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

The `+` in the navigation bar opens the existing shelf form, and the form **does not write**: it
returns a draft onto the stack. The draft appears as a section straight away, marked `Nouvelle`,
and accepts drops like any other. That is the one behavioural difference from the carousel's
create action, and it is what makes "create it, fill it, then save" a single movement.

A draft carries a prefixed client id, mirroring the optimistic-placeholder convention of ADR 0001,
so a placeholder is never mistaken for a server document.

Two rules the write plan already has to honour, now reachable by hand:

- a draft named like an existing étagère, or like another draft, is **refused at the form** —
  compared the way auto-sort compares names, trimmed and insensitive to case and diacritics, so
  applying can never produce two étagères the user reads as the same;
- a draft left empty is **not created**, and the recap says it was dropped rather than silently
  omitting it. Creating an empty étagère because a form was opened leaves the user a shelf to go
  and delete.

## Acceptance criteria

- [ ] The `+` opens the shelf form, and confirming it writes nothing to the server
- [ ] The new étagère appears immediately as a section marked `Nouvelle` and accepts drops
- [ ] A name matching an existing étagère or another draft is refused in the form, whatever the
      case and the accents
- [ ] A draft holding books is created on apply, with its books
- [ ] A draft left empty is not created, and the recap names it as dropped
- [ ] Discarding the stack removes the drafts with it
- [ ] The naming rule and the empty-draft rule are asserted without a store

## Blocked by

- issues/0040-sorting-surface-apply.md
