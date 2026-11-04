# A book row names three authors at most

Shipped on 2026-11-04, iOS only (issue #32). Before this change, a book row (`InventoryCell`) joined every name of
`Edition.displayedAuthorNames` with « , ». « Le grand livre du climat », with more than a hundred authors, filled a
whole screen of a friend's profile on its own.

## What it does

- Three names or fewer → every name, « , »-joined, as before.
- More than three → the first three, in `displayedAuthorNames` order, then « et N autres »:
  - 4 authors → « A, B, C et 1 autre »
  - 101 authors → « Greta Thunberg, Peter Brannen, Beth Shapiro et 98 autres »
  - in English, « and 1 other » / « and 98 others »
- No comma before « et ». No `lineLimit`: three long names may still wrap past two lines, and that was accepted.
- No author → no line, as before.

The first idea was two lines and an ellipsis. Olivier chose the count instead, which is easier to read, and dropped
the line limit.

## Technical surface

- `Model/Books/AuthorNamesSummary.swift`: a pure value type. `shownNames` holds the first three names,
  `hiddenCount` how many are left out, and `text` the line to display. Its tests, `Tests/AuthorNamesSummaryTests.swift`,
  cover 0, 1, 3, 4 and 101 names. They accept the suffix in French or English, so they pass whatever the simulator's
  language, and they fail if the catalog key is missing.
- `Localizable.xcstrings`: `inventory.authors.others %lld`, plural one/other in `fr` and `en`.
- `InventoryCell` calls `AuthorNamesSummary(authorNames).text`. Inventaire, a friend's profile, Recherche and an
  étagère's detail all use this cell.

## Not done

- `ShelfFocusBookCell`, the book screen and the lists still show every name.
- Android: its `BookRow` already cuts the authors to one line with an ellipsis, so it was left as it is.
- Installed on an iPhone. No screenshot was taken and e2e was not run.
