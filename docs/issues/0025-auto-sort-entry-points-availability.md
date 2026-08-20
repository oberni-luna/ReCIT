Title: Auto-sort — entry points and Apple Intelligence availability
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0006-ai-auto-sort.md

## What to build

Two entry points, and honest handling of the three ways Apple Intelligence can be unavailable.

### The empty-state étagère becomes the trigger

The empty-state card's label already reads as a note to tidy one's books, so tapping it doing
exactly that is well earned. **The whole card is the target, not just the label** — splitting a
painted card into two hit zones is the problem the shelf card's pencil removal solved.

The manual create path is not lost: the "Ajouter" action in the section header covers it.

### Settings is the other, and the more important one

The empty card only exists for a user with **no** étagères. Auto-sort is just as useful for
someone with three shelves and two hundred unfiled books — for whom the settings entry is the
*only* route. It is the primary entry point; the card is the discoverable shortcut.

### Three unavailability reasons, treated differently

Not one blanket "unavailable":

- **Device not eligible** — the user can do nothing about it, so **hide** the entry point.
  Explaining costs them a nag they cannot act on.
- **Apple Intelligence switched off** — actionable, so **say so** and offer a route to
  Settings.
- **Model still downloading** — transient, so **show it disabled** and say it will be
  available shortly.

### The fallback

The empty card cannot be hidden — it *is* the empty state. On an ineligible device it falls
back to opening the create form, which is its behaviour today, so it is never a dead end.

> **Amended after shipping.** This was built as specified and then removed. A card reading
> "Todo — ☐ Ranger mes livres" that silently opens a *create-shelf* form does not read as
> "your device cannot do this", it reads as the wrong screen — and because the fallback was
> silent, the failure was invisible. The card now always leads into the flow, which states
> the reason out loud. The manual route was never at risk either way: the section header's
> "Ajouter" creates an étagère by hand. `AutoSortEntryPoint.reachesFlow` was deleted with it.

### This supersedes shipped behaviour

Issue 0011 shipped with the criterion *"Tapping anywhere on the card opens the create form"*.
That becomes conditional on the AI being unavailable. **Amend issue 0011's acceptance criteria
and the feature doc that describes it** rather than letting the record drift — the file says
one thing and the app will do another otherwise.

## Acceptance criteria

- [ ] Tapping anywhere on the empty-state étagère card starts the auto-sort flow.
- [ ] The section header's "Ajouter" action still creates an étagère by hand.
- [ ] The settings screen offers auto-sort, and reaches it for a user who already has étagères.
- [ ] On an ineligible device the settings entry point is not shown.
- [ ] ~~On an ineligible device the empty-state card opens the create form instead, exactly as it does today.~~ *(Withdrawn — see the amendment above. The card leads into the flow on every device; the flow says why it cannot run.)*
- [ ] With Apple Intelligence switched off, the entry point is shown with an explanation and a route to Settings.
- [ ] With the model still downloading, the entry point is shown disabled and described as temporarily unavailable.
- [ ] Enabling Apple Intelligence and returning to the app makes the feature usable without a relaunch.
- [ ] Issue 0011's acceptance criteria are amended to record that the create-form tap is now the unavailable-AI fallback.
- [ ] The feature doc describing the empty-state card is amended to match.
- [ ] `docs/` and its root-level duplicate stay identical.

## Blocked by

- issues/0023-auto-sort-plan-generation.md — builds the flow these entry points launch.
