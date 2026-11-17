# Recherche

One field for my books, my friends', my lists and my friends' lists, my friends, my groups, and inventaire.io. At rest, recent searches and what friends just shelved. A result opens a book, the best edition of its work.

## Code

- `Features/Search/` — `SearchTabView`
- `AppModels/Search/` — `SearchModel`
- `docs/wiki/prd/0014-search-results-are-editions.md` — open PRD, issue #11

## Decisions

- [ADR 0002](adr/0002-unified-book-detail.md)

## Features

- [0014 Unified search, in the inventory screen](features/0014-unified-inventory-search.md) — one field for my books, my friends' and inventaire.io; the Recherche tab retires (it came back in 0037)
- [0037 A Recherche tab, and what my friends just shelved](features/0037-search-tab.md) — the search leaves the inventory for a tab with the system's search role; at rest, the recent searches and my friends' ten latest books in « Ranger mes livres »'s cards, gone at the first character; `TabRouter` for the cross-tab asks; e2e not run
- [0092 Links to a book or an author](features/0092-entity-deep-links.md) — a `link.exlibris.lunabee.ovh/entity/<uri>` link pushes the Fiche livre or the Auteur·ice on Recherche, alone above its root
- [0040 Recherche's field always there, a list's detail on black](features/0040-search-field-pinned-list-detail-on-black.md) — on iOS 27 the search tab sits in the bar and its field is pinned under the title (`.navigationBarDrawer(.always)`), iOS 26 unchanged; `EntityListDetail` on `backgroundGrouped`; real app unseen on iOS 27, list detail unseen
- [0087 Nouveau livre from Recherche, with an optional ISBN](features/0087-book-creation-from-search.md) — the « Sur inventaire.io » absence offers « Ajouter ce livre », which opens « Nouveau livre » on the query; the ISBN typed or left empty, its check digit holding back « Publier »; drafts kept by query in memory; the Fiche livre pushed once published; nothing published, e2e not run
- [0098 Lists, friends and groups in Recherche, and « Ajouter une édition » under every answer](features/0098-lists-friends-and-groups-in-search.md) — Listes, Ami·es, Groupes after the books from three characters, three rows and « Tout voir »; friends only, my groups only, lists by name; « Ajouter une édition » closes inventaire.io's answer with or without results (amends 0087); iOS only, e2e not run
