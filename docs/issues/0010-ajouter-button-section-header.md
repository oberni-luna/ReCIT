Title: "Ajouter" button in the "Étagères" section header
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0003-shelf-label-and-add-affordances.md

## What to build

Let the user create an étagère without swiping the carousel to its end. Add a small green
**Ajouter** button to the right of the "Étagères" section header; pressing it opens the
existing create form.

Promote the section header from a view-returning function into its own view type carrying a
title and an *optional* trailing action — the project's conventions rule against splitting
sub-views into functions or computed properties. "Étagères" gets the action; "Tous les
livres · N" uses the same type without one.

Style it as a plain button tinted with the app's tinted foreground role, not the secondary
grey: this becomes the primary way to create an étagère, and grey reads as decorative. The
design system's three named button styles are all full-width large buttons, far too heavy
for a section header, so style it directly rather than inventing a style for one call site.
The action label is small, so give it vertical padding and an explicit content shape so the
tap target clears the minimum.

This slice is additive — the trailing create card stays in the carousel and keeps working.
It is retired in a later slice, which is why this one lands first.

## Acceptance criteria

- [ ] The "Étagères" section header shows a trailing "Ajouter" action with a plus icon and its title.
- [ ] Pressing it opens the same create form as the trailing card does.
- [ ] The action is tinted green, not secondary grey.
- [ ] Its tap target clears the platform minimum despite the small text.
- [ ] The header is a dedicated view type taking a title and an optional action.
- [ ] The "Tous les livres · N" header uses the same type, with no action, and looks unchanged.
- [ ] The trailing create card still exists and still works — nothing is removed in this slice.
- [ ] Creating from the header lands the new shelf in the carousel without a manual refresh.

## Blocked by

None - can start immediately. Independent of 0008 and 0009.
