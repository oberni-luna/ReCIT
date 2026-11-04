# Recherche

One field for my books, my friends' and inventaire.io. At rest, recent searches and what friends just shelved. A result opens a book, the best edition of its work.

## Code

- `Features/Search/` — `SearchTabView`
- `AppModels/Search/` — `SearchModel`
- `docs/wiki/prd/0014-search-results-are-editions.md` — open PRD, issue #11

## Decisions

- [ADR 0002](adr/0002-unified-book-detail.md)

## Features

- [0014 Unified search, in the inventory screen](features/0014-unified-inventory-search.md) — one field for my books, my friends' and inventaire.io; the Recherche tab retires (it came back in 0037)
- [0037 A Recherche tab, and what my friends just shelved](features/0037-search-tab.md) — the search leaves the inventory for a tab with the system's search role; at rest, the recent searches and my friends' ten latest books in « Ranger mes livres »'s cards, gone at the first character; `TabRouter` for the cross-tab asks; e2e not run
- [0040 Recherche's field always there, a list's detail on black](features/0040-search-field-pinned-list-detail-on-black.md) — on iOS 27 the search tab sits in the bar and its field is pinned under the title (`.navigationBarDrawer(.always)`), iOS 26 unchanged; `EntityListDetail` on `backgroundGrouped`; real app unseen on iOS 27, list detail unseen
