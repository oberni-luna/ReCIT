# Lists, friends and groups in Recherche, and « Ajouter une édition » under every answer

Shipped on 2026-11-16, iOS only (issue #119). Recherche searched books only: mine and my friends' copies, then
inventaire.io. Now it also finds what the phone already holds about people and lists: my lists and my friends'
lists, my friends, my groups. Nothing new is asked of inventaire.io. Mockups: Figma, page Search, section
« Recherche · Listes, ami·es et groupes » (S1 `1018:809`, S2 `1018:6682`, spec `1019:1216`). It amends
[0087](0087-book-creation-from-search.md): the button under inventaire.io's answer no longer waits for an empty
answer.

## What it does

- From three characters on, three sections follow « Dans mes livres et chez mes ami·es », in this order:
  - **Listes**: my lists by name, then my friends' lists (« Dans mon réseau »), the most recently changed first.
    Every type of list: works, authors, publishers. The name is searched, never the description. A friend's list
    carries the friend's picture and name, as in the Listes tab, and opens read-only.
  - **Ami·es**: my friends only, by username. A reader with a pending invitation, sent or received, is not there:
    Réseau's « Ajouter des ami·es » is where readers are looked up. A touch opens the Profil d'un ami.
  - **Groupes**: the groups I am a member or an admin of, by name. Invitations and requests sent stay in Réseau, with
    their buttons. A touch opens the group's screen.
- The sections show while the query is typed and stay once it is sent, like the books; inventaire.io comes after
  them. A section with no match is not drawn.
- Each section shows three rows at most. Past three, its header shows « Tout voir », which opens every match in the
  same rows, titled like the section. At exactly three, no « Tout voir ».
- **« Ajouter une édition »** (« Add an edition ») closes inventaire.io's answer, in a card of its own, whether there
  are results or none: a result may not be the book searched for. It opens « Nouveau livre » on the query, which
  looks for the work first ([0047](0047-new-book-work-first.md)), so a work already on inventaire.io leaves only the
  edition to describe. With no result, the empty state stays without a button and the row comes under it. A failed
  call shows « Réessayer » only.

## Technical surface

- `Model/SearchResult/LocalSearchMatches.swift`: `LocalSearchMatches<Element>`, the matches a section draws (`items`,
  `totalCount`, `isCapped`). `matching(_:limit:find:)` holds the one rule: the query is trimmed, a blank query
  matches nothing, the cap comes after matching. `InventorySearchRanking.rank` goes through it too.
- `+Friends` keeps `User.isStoredFriend` (`Model/UserData/User+StoredFriend.swift`: still in the store and
  `relation == .friend`) and matches the username; `+Groups` filters `MyGroups.mine` by name;
  `Features/Search/LocalSearchMatches+Lists.swift` wraps the Listes tab's `ListsTabSections` and returns
  `ListSearchMatch` (a list, and its owner for a friend's).
- `LocalSearchSectionsReader` owns the three `@Query`s (lists, users, `StoredGroup`) and hands a `LocalSearchSections`
  to `SearchListsFriendsGroupsSections`, capped at three, inserted in `SearchContent` after `SearchLocalSection`, and
  to the « Tout voir » screens, uncapped.
- `SearchMatchesSection` draws one section; `SearchListRow`, `SearchFriendRow`, `SearchGroupRow` reuse `ListRowView`,
  `UserCellView` and `GroupRowView`. Ids `e2e.searchList`, `e2e.searchFriend`, `e2e.searchGroup`, and `.seeAll` on
  each header.
- « Tout voir » is `NavigationDestination.localSearchResults(query:kind:)` with `LocalSearchKind` (books, lists,
  friends, groups), rather than three new cases: the SwiftLint baseline pins `viewForDestination`'s complexity.
  `SearchAllMatchesView` sends books to `SearchAllLocalView`, unchanged, and the rest to `SearchAllMatchesList`.
  `SearchLocalHeader` takes the kind.
- `SearchAddEditionRow` is the tinted row, id `e2e.searchAddEdition` (was `e2e.searchNoResult.addBook`); key
  `inventory.search.results.add_edition` replaces `inventory.search.results.empty.add_book`. `SearchRemoteSection`
  puts it after the results and after the empty state.
- `SearchContent` went from 407 to 398 lines (`SearchAttempt` moved to `SearchContent+SearchAttempt.swift`), and its
  `file_length` baseline entry was removed.
- Previews read a seeded store, `SearchLocalPreviewStore`; `GroupModel.signedInReaderKey` became internal for it.
- Tests: `LocalSearchMatchesTests`, `…FriendsTests`, `…GroupsTests`, `…ListsTests`.

## Not done

- Android: Recherche unchanged, and its « Nouveau livre » button still reads « Ajouter ce livre »; for the next
  Android catch-up.
- Seen on an iPhone by the reader for the sections; « Tout voir » screens, the new row and the previews' groups not
  seen running. No PR screenshots: the only signed-in simulator was in use by another task. e2e not run.
