---
issue: 32
status: to-close
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

Round 1 — 2026-11-04.

- `Model/Books/AuthorNamesSummary.swift` (new): `struct AuthorNamesSummary` — `shownNames` (first ≤ 3), `hiddenCount`, `text` (« , »-join, then a space and the plural suffix past three).
- `Localizable.xcstrings`: `inventory.authors.others %lld`, plural one/other — fr « et %lld autre » / « et %lld autres », en « and %lld other » / « and %lld others ».
- `Features/Inventory/InventoryCell.swift`: `Text(AuthorNamesSummary(authorNames).text)`; `isEmpty` guard kept, no `lineLimit`.
- `Tests/AuthorNamesSummaryTests.swift` (new): 0, 1, 3, 4, 101 names. The translated suffix is not asserted (depends on the simulator's language): prefix, count, order and absence of the fourth name are.
- Proof: `-only-testing:ReCIT_iOSTests/AuthorNamesSummaryTests` → `** TEST SUCCEEDED **` 5/5; `-scheme ReCIT_iOS build` → `** BUILD SUCCEEDED **`, SwiftLint clean.

## Review

Round `validation` — 2026-11-04, at `/wa-close 32`. Scope `origin/main...HEAD`. LENSES: style ✓ · elegance ✓ · structure ✓ · correctness ✓.

- 🟡 `Tests/AuthorNamesSummaryTests.swift:47` — [correctness] the 4- and 101-name tests never asserted the suffix; a missing catalog key (raw-key fallback) would pass. — fixed by autofix: `hasSuffix("1 other" | "1 autre")`, `hasSuffix("98 others" | "98 autres")`, no `inventory.` in the text. Re-verified clean, 5/5 green.

## Verification

Round 1 — manual validation, not run by agent.

- Installed on Olivier's iPhone (Debug, branch `wa/32-shorten-book-row-authors`); tested by Olivier before `/wa-close`.
- PR screenshots skipped: the iPhone 17 simulator is signed out.

## Feedback
