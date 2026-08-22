## Parent

`docs/prd/0009-grid-shelf-sorting.md`

## What to build

The sorting screen is the app's recommended way to file books, and drag-and-drop does not
exist under VoiceOver. This slice keeps the screen usable without a drag.

- A **custom accessibility action on each book card**: « Ranger dans… », which offers the
  étagères and the drafts by name and files the book into the chosen one — the same
  `SortChange` a drop records.
- The **reverse on an étagère card**: an action that takes its top book off and returns it to
  the books to file.
- The étagère card's accessibility label reads its name, its count, and its pending status
  when it has one, so the pill and the count are not information reserved to sighted users.
- Book cards and covers carry labels naming the book; the piled covers behind the top one are
  not individually focusable — they are decoration for a shelf whose contents are reachable by
  opening it.
- Both actions are withdrawn while a run is in flight, like every other gesture.

## Acceptance criteria

- [ ] With VoiceOver on, a book card offers « Ranger dans… » and filing it works end to end.
- [ ] An étagère card offers an action returning its top book to the books to file.
- [ ] An étagère card's label states its name, its count and its pending status.
- [ ] The pile's lower covers are not separately focusable.
- [ ] Accessibility actions are unavailable while an apply or a proposal runs.
- [ ] Filing this way lands in the same stack, with the same recap, as a drop.

## Blocked by

- `issues/0047-drag-a-book-between-sections.md`
