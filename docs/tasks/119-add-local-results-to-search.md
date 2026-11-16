---
issue: 119
status: to-test
wiki: [[search]], [[lists]], [[network]], [[features/0037-search-tab]], [[features/0087-book-creation-from-search]]
note: Mockups in Figma S7IvC6GvlcUFe5IgbtvQq6, page Search, section « Recherche · Listes, ami·es et groupes » (1018:808) — S1 1018:809, S2 1018:6682, spec 1019:1216.
created: 2026-11-16
---

## Context / Decisions

> ajouter dans les résultats de la recherche globale : les listes, les ami.e.s, les groupes en local
>
> Ajout du 2026-11-13 : « Ajouter ce livre » toujours en bas des résultats inventaire.io, pas seulement quand il n'y en a aucun — des résultats peuvent ne pas correspondre au livre cherché.

Recherche finds more than books in the store: my lists and my friends' lists, my friends, my groups. Nothing new is asked of inventaire.io. The mockups are S1 (suggestions) and S2 (results) in Figma.

- **Three new local sections: Listes, Ami·es, Groupes.** They show from the suggesting phase (3 characters) and stay in the results phase, like « Dans mes livres et chez mes amis ».
- **Order:** books, Listes, Ami·es, Groupes, then inventaire.io (« Chercher sur inventaire.io » in S1, the remote results in S2).
- **A section with no match is not drawn**, like the books section.
- **Listes: every type** (works, authors, publishers). Mine, then my friends' (« Dans mon réseau »), matched on the name only with `localizedStandardContains`. Reuse `ListsTabSections`, the Lists tab's filter. A friend's list carries the friend's picture and name, as in the Lists tab. Tap → the Liste, read-only for a friend's.
- **Ami·es: `relation == .friend` only**, matched on the username. No invitations, no other readers: Réseau's « Ajouter des ami·es » searches readers. Tap → the friend's profile.
- **Groupes: groups I am a member or an admin of**, from `StoredGroup`, matched on the name. No invitations, no sent requests: they live in Réseau with their buttons. Tap → the group's screen.
- **Three rows at most per section.** « Tout voir » in the header only when the cap hides something (strictly more than 3). It pushes one screen per section on the search tab's path, with the same rows and no cap, like `SearchAllLocalView` for books.
- **« Ajouter une édition » always ends the inventaire.io results**, whether there are results or none: a result may not be the book searched for. One tinted row (`Row / Link`, Tone=Tinted), in its own section with no header, under the last remote group. Tap → Nouveau livre on the query (`openNewBook(.search(query:))`, feature 0087).
- **No result:** the empty state stays, without its button; the same « Ajouter une édition » row sits under it. One button, always in the same place.
- **Failure:** no « Ajouter une édition », only « Réessayer ».
- **Label everywhere « Ajouter une édition »**, English « Add an edition ». The key `inventory.search.results.empty.add_book` changes its text, or is replaced by a key named for the row.
- **Rows reuse what exists:** the Lists tab's list row (`ListRowView` with the friend header for a friend's list), the friend cell of Réseau, the group cell of Réseau (`GroupCellView` / `GroupRowView`). No new component.
- **Ranking and caps stay pure**, in `Model/SearchResult/` like `InventorySearchRanking`, testable without a `ModelContainer`.
- **iOS only.** Android follows in its own catch-up task.

## Acceptance criteria

- Query « bel » (3 characters, not sent) with a matching list, friend and group in the store → sections in order: « Dans mes livres et chez mes amis », Listes, Ami·es, Groupes, « Chercher sur inventaire.io ».
- Same query sent → the four local sections stay, the inventaire.io groups follow, then « Ajouter une édition ».
- A query matching no friend → no Ami·es section (same for Listes, Groupes).
- A friend's list matching the query shows under Listes with the friend's picture and name; tap → the Liste, read-only.
- A list of authors whose name matches shows under Listes.
- A list whose description matches but not its name → not shown.
- A reader with a pending invitation, sent or received, matching the query → not shown.
- A group I was invited to, or asked to join, matching the query → not shown.
- Tap a friend → their profile. Tap a group → the group's screen.
- 4 friends match → 3 rows and « Tout voir »; tap → a screen listing all 4. Exactly 3 match → no « Tout voir ». Same for Listes and Groupes.
- Remote results found → « Ajouter une édition » under the last group; tap → Nouveau livre with the query.
- No remote result → the empty state with no button, then « Ajouter une édition ».
- Remote call failed → « Réessayer », no « Ajouter une édition ».
- Unit tests cover the matching, filtering and caps of the three sections.

## Implementation

- **Pure matching** in `Model/SearchResult/`: `LocalSearchMatches<Element>` (items, totalCount, `isCapped`; one `matching(_:limit:find:)` holds the trim, blank-query and cap rules), `+Friends` (`relation == .friend`, username), `+Groups` (over `MyGroups.mine`, name). Lists in `Features/Search/LocalSearchMatches+Lists.swift` over `ListsTabSections` (mine by name, then network), with `ListSearchMatch` (list + owner).
- **Sections**: `SearchListsFriendsGroupsSections` (own `@Query`s) inserted after `SearchLocalSection` in `SearchContent`; one generic `SearchMatchesSection`, rows `SearchListRow`, `SearchFriendRow`, `SearchGroupRow` reusing `ListRowView`, `UserCellView`, `GroupRowView`. Headers keys `inventory.search.section.lists|friends|groups`.
- **« Tout voir »**: `NavigationDestination.localSearchResults(query:kind:)` with `LocalSearchKind` (books default); no new case, so `viewForDestination` complexity stays at its baseline. `SearchAllMatchesView` routes books to `SearchAllLocalView`, the rest to `SearchAllMatchesList`. `SearchLocalHeader` takes the kind.
- **« Ajouter une édition »**: `SearchAddEditionRow` in its own section after the results and after the no-result empty state (which lost its button); none on failure. Key `inventory.search.results.add_edition` replaces `inventory.search.results.empty.add_book`; id `e2e.searchAddEdition`.
- `SearchContent` down to 398 lines (`SearchAttempt` moved to `SearchContent+SearchAttempt.swift`).
- Build green (SwiftLint clean); tests: LocalSearchMatches (4 suites), InventorySearchRanking, ListsTabSections, MyGroups, RemoteSearchState → 53 passed.
- Android `strings_create_book.xml` still says « Ajouter ce livre » and names the removed iOS key in a comment: Android catch-up.

## Verification

manual validation — not run by agent
