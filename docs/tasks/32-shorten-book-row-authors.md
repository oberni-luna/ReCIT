---
issue: 32
status: todo
wiki: [[architecture]], [[testing]]
note: il faut limiter la longueur des auteurs dans une cell d'inventaire, à 2 lignes
created: 2026-11-04
---

## Context / Decisions

> il faut limiter la longueur des auteurs dans une cell d'inventaire, à 2 lignes

- **Problem:** `InventoryCell` (the book row, glossary « Ligne livre ») joins every name of `edition.displayedAuthorNames` with no limit. « Le grand livre du climat » (100+ authors) fills a whole screen in a friend's profile.
- **Rule:** at most three names. More than three → the first three, then « et N autres ».
  - 4 authors → « A, B, C et 1 autre ». 101 authors → « A, B, C et 98 autres ».
  - 3 or fewer → unchanged, names joined with « , » as today.
- **No `lineLimit`** (Olivier): three long names may wrap past two lines; accepted.
- **Copy:** one plural string in `Localizable.xcstrings`, fr « et %lld autre » / « et %lld autres », en « and %lld other » / « and %lld others ». No comma before « et » / « and ».
- **Where:** the summary is a pure function on a value type in `Model/Books/` (pure decisions live in `Model/`, `architecture-recit.md`), tested with Swift Testing. `InventoryCell` calls it; nothing else changes.
- **Out of scope (YAGNI):** `ShelfFocusBookCell` and every other place listing authors (book screen, lists); Android, whose `BookRow` already cuts authors to one line with an ellipsis.

## Acceptance criteria

- [ ] A book row of an edition with 101 authors shows « Greta Thunberg, Peter Brannen, Beth Shapiro et 98 autres » (first three names in `displayedAuthorNames` order), French UI.
- [ ] Same row, English UI → « Greta Thunberg, Peter Brannen, Beth Shapiro and 98 others ».
- [ ] 4 authors → « A, B, C et 1 autre ».
- [ ] 1, 2 or 3 authors → all names, « , »-joined, as before. 0 authors → no author line.
- [ ] Unit tests cover 0, 1, 3, 4 and 101 names.
- [ ] Book rows in Inventaire, a friend's profile and Recherche all show the capped line (they share `InventoryCell`).

## Implementation

## Review

## Verification

## Feedback
