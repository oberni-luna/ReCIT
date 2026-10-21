# 0020 — Un onglet Recherche, et ce que mes amis viennent de poser sur leurs étagères

Pas de maquette. Décisions prises en grill le 2026-10-21. Revient en partie sur
[0014 — la recherche unifiée](../features/0014-unified-inventory-search.md), qui avait retiré
l'onglet Recherche pour loger le champ dans l'inventaire.

## Problem Statement

Pour chercher un livre, je dois d'abord aller dans l'inventaire et faire apparaître le champ caché
dans la barre de navigation. Rien dans la barre d'onglets ne dit que l'app sait chercher : sur
iOS 26, toutes les apps que j'utilise posent leur recherche en bas à droite, dans sa propre
pastille, et Ex-libris est la seule où il faut savoir qu'elle est dans un autre écran.

Le champ de l'inventaire a un autre défaut : quand je ne tape rien, il n'a rien à me montrer. Tant
que le champ n'est pas ouvert, c'est mon inventaire qui occupe l'écran ; dès qu'il l'est, ce sont
mes trois dernières recherches, et c'est tout. Pourtant l'app sait quelque chose qui m'intéresse
sans que je le demande : ce que mes amis viennent d'ajouter chez eux. Aujourd'hui je ne le vois
qu'en ouvrant le profil de chacun.

## Solution

Un cinquième onglet, **Recherche**, avec le rôle système `search` : iOS le pose à part, au bout de
la barre, avec sa loupe. L'inventaire perd son champ. Il n'y a toujours qu'un seul champ de
recherche dans l'app, il est simplement là où on l'attend.

Au repos, l'onglet n'est pas vide : mes dernières recherches, puis **« Chez mes amis »**, un
carrousel des derniers livres ajoutés par mes amis, dans les cellules mêmes de « Livres à ranger ».
C'est de la découverte, pas une réponse : **le carrousel s'en va au premier caractère tapé.** Une
fois que je cherche, les livres de mes amis répondent là où ils répondaient déjà, dans la section
locale, à côté des miens.

## User Stories

1. As a reader, I want a Recherche tab in the tab bar, so that I can find a book without knowing which screen hides the field.
2. As a reader on iOS 26, I want the Recherche tab to sit apart at the end of the bar with the system magnifying glass, so that it looks and behaves like search in every other app.
3. As a reader, I want the inventory screen to no longer carry a search field, so that there is exactly one place where I search.
4. As a reader, I want selecting the Recherche tab to leave the keyboard down, so that I can see what the tab has to show me before deciding to type.
5. As a reader, I want tapping the field to raise the keyboard, so that I can start typing.
6. As a reader, I want tapping the Recherche tab again while I'm already on it to bring me back to its root and raise the keyboard, so that one gesture always gets me to a fresh search.
7. As a reader, I want my query, my results and any book I opened from them to still be there when I come back to the tab, so that switching tabs doesn't lose my place.
8. As a reader, I want coming back to results I already have not to ask inventaire.io again, so that the list doesn't flicker and nothing is spent on a question already answered.
9. As a reader, I want to see my last three searches when the field is empty, whether or not the keyboard is up, so that I can go back to something I already looked for.
10. As a reader with no recent search, I want the empty state that says so, so that an empty tab doesn't look broken.
11. As a reader, I want a « Chez mes amis » carousel under my recent searches, so that I discover what my friends have just added without opening each profile.
12. As a reader, I want that carousel to show my friends' most recently added books first, so that it reads as news.
13. As a reader, I want at most ten covers in the carousel, so that it stays a glance and not a catalogue.
14. As a reader, I want a « Tout voir » on the carousel when my friends have more, so that I can go through all of it.
15. As a reader, I want tapping a cover to open that book, so that the carousel behaves like every other book in the app.
16. As a reader with no friend yet, I want a paper tag in place of the carousel that takes me to the Réseau tab, so that I learn how to fill it.
17. As a reader whose friends have no books, I want the carousel to be absent, so that I'm not shown an empty band.
18. As a reader whose friends are still syncing, I want the carousel to appear as soon as the first book arrives and fill as the others do, so that I don't wait behind a spinner that the Réseau tab already shows.
19. As a reader, I want the carousel to leave as soon as I type a character, so that discovery doesn't sit among the answers to my query.
20. As a reader, I want the carousel's departure and the sections that replace it to move as one animation, so that typing doesn't make the screen jump.
21. As a reader typing three characters or more, I want my books and my friends' in one local section, as before, so that the answer to "who has this?" stays in one place.
22. As a reader, I want the carousel's cards to be the ones « Ranger mes livres » shows, so that a book looks the same wherever it sits in a row.
23. As a reader, I want « Tout voir » on the carousel to list all my friends' most recent books, so that I can go past the ten covers.
24. As a reader looking at an empty shelf, I want its « Rechercher » tag to take me to the Recherche tab with the keyboard up, so that the tag still does what it says.
25. As a reader, I want submitting a query, tapping a suggestion or tapping a recent search to behave exactly as before, so that the move doesn't change how search answers.
26. As a reader, I want loading, no-result and failure states of the inventaire.io section to behave exactly as before, so that the move doesn't lose them.
27. As a reader, I want pulling down on the results to refresh them, as before, so that I can still ask the same question twice on purpose.
28. As a VoiceOver user, I want the carousel to announce each book's title and owner, so that I can browse it without seeing the covers.
29. As a reader using a large Dynamic Type size, I want the carousel to stay legible, so that the move doesn't break accessibility.
30. As the owner, I want the end-to-end scenario to drive the Recherche tab, so that its compte-rendu keeps covering search.
31. As the owner, I want the existing `e2e.*` identifiers and the `inventory.search.*` catalogue keys kept, so that compte-rendus stay comparable and no translation is redone.

## Implementation Decisions

**The spike settled it the other way (issue 0115, 2026-10-21).** The carousel was first built to
stay while typing, filtered on the query and shrunk so inventaire.io stayed above the keyboard. Two
things killed it: the compact size did not keep the suggestions above the keyboard anyway (three
local rows already reach its edge), and going back from three characters to two removed the local
section while leaving the friends' carousel alone on screen. **The carousel is discovery, shown
in the rest phase only; it has a single size, and the local section keeps mixing my books and my
friends'.** No size rule in `SearchPhase`, no ranking per scope.

**`SearchPhase` — modified, pure.** It stops taking the focus into account: `current(query:
submittedQuery:)` is decided by the text and by what was sent, and never returns `nil` any more —
the « nothing to show, the inventory is back » case only existed because the surface lived inside
the inventory. Empty text is `recents`; one or two characters `typing`; three or more `suggesting`;
a matching submission `results`. The three-character threshold stays its only copy.

**`InventorySearchRanking` — unchanged.** One local section, my books and my friends', mine first,
capped at three.

**`FriendsCarouselState` — new, pure.** From the phase, my friends' items and whether I have any
friend at all, it answers one of: the invitation (no friend: the paper tag toward Réseau), hidden
(friends with no book, or any phase but the rest), or the ten most recent ones with their total.
« Having a friend » is read from the users already in the store with the accepted relation, not
from a server call.

**`TabRouter` — new, `@Observable @MainActor`, injected into the environment.** It owns the
selected tab (which leaves `MainTabView`'s `@State`) and a request to raise the search field. Three
things go through it: the empty shelf's « Rechercher » tag (select the Recherche tab and raise the
field), the carousel's invitation tag (select Réseau), and a tap on the Recherche tab while it is
already selected (pop the tab's stack to its root, then raise the field). The Recherche tab's root
consumes the field request once and clears it.

**The tab bar.** `TabConfig` gets a `search` case with a role, which iOS lays out apart at the end
of the bar whatever its position in `allCases`. Its title comes back under `tab.search`. The
Réseau badge and the shelf focus overlay are untouched.

**The Recherche tab's root — new view, own `NavigationStack` and path.** It carries `.searchable`
(with `isPresented` bound, so the router can raise it), the submission, and `.onSubmit(of:
.search)` — everything `ShelvesView` holds today for search, moved as is. Books opened from search
are pushed on this tab's path, not the inventory's. State lives as long as the tab does; nothing
resets it on leaving.

**The inventory.** `ShelvesView` loses `.searchable`, the submission, `isSearchPresented` and
`.onSubmit`; `ShelvesContent` loses its `isSearching` branch and its `onSearch` callback, which is
replaced by the router.

**The search screens move.** Everything named `InventorySearch*` moves to the Search feature folder
and drops the `Inventory` prefix. The catalogue keys `inventory.search.*` and the `e2e.*`
identifiers are kept unchanged.

**The carousel's « Tout voir »** pushes a new destination listing my friends' books, most recent
first, with no query. `localSearchResults(query:)` is unchanged.

**The carousel cell is `SortBookCardView`**, the card « Ranger mes livres » shows a book waiting to
be filed — same width (`SortGridMetrics.bookColumnWidth`), same spacing, title under the cover, no
avatar. Its accessibility label names the book and the owner. It opens the same book detail as any
other inventory row. The cards are drawn only once the row's width is known: a card laid out at
zero has its cover decoded for a zero-sized frame, and `CachedAsyncImage` never asks again.

**The list animates on the phase's step** (rest, typing, suggesting, results), not on the query, so
the carousel leaving and the sections arriving are one movement while a keystroke that only
refilters is not animated.

**Unchanged:** recents recorded on submit only, the three suggestions, `RemoteSearchState`, the
`answered` guard against re-asking inventaire.io, retry, the results' `.refreshable`. Nothing new is
persisted and nothing writes to the server, so ADR 0001's optimistic path is not involved; the
carousel reads a reactive `@Query`.

**End-to-end.** The three search steps drive the Recherche tab instead of the inventory field;
leaving search becomes selecting the inventory tab rather than tapping « Annuler ». Running
`scripts/e2e.sh` stays the owner's step.

## Testing Decisions

Good tests here drive the pure types with values and assert on what they answer, never on how
they compute it: a phase from a string and a submission, a carousel state from a handful of items,
a tab selection from a sequence of requests. No `ModelContainer`, no keyboard, no network.

- **`SearchPhase`** — every phase from text and submission alone; the focus no longer matters;
  whitespace-only text is the rest state. Prior art:
  the existing phase tests next to `InventorySearchRankingTests`.
- **`FriendsCarouselState`** — invitation with no friend; hidden with friends and no book; hidden in
  every phase but the rest; the ten most recent at rest, with the total. Prior art:
  `RemoteSearchStateTests`.
- **`TabRouter`** — the shelf tag selects Recherche and raises the field once; the invitation tag
  selects Réseau; re-selecting Recherche asks for a pop and a field; the field request is consumed
  once. Prior art: `OnboardingStoreTests` for an observable model driven by values.
- **The carousel leaving** is judged by eye on the simulator, not by a test.
- **The end-to-end scenario** is updated but not run by the implementation.

## Out of Scope

- The Android app (`Recit_Android/`): it gets its own issue later.
- Any discovery source other than my friends' books — inventaire.io's recent publications, groups'
  books, my lists and étagères.
- A Figma frame for the Recherche tab. The `Chrome / Tab Bar` variant is recorded as a divergence in
  the Figma library notes, not redrawn.
- Changing what a remote result opens — that is PRD 0014 (results are editions), still open.
- Per-entry deletion of recent searches, unchanged since 0014.

## Further Notes

- **PRD 0014 (search results are editions) is still open** and its issues touch the inventaire.io
  section and its rows. Renaming `InventorySearch*` will conflict with any branch working on them;
  whichever lands second rebases.
- The keyboard edge sits around 516 pt on an iPhone 17 per feature 0014, and three local rows
  already reach it — which is why no carousel, of any size, can sit between them and inventaire.io
  while typing.
- One or two characters show nothing today: recents only draw in the rest phase. That is 0014's
  behaviour, kept; with the carousel leaving at the first character, it is worth a look on device.
- When the feature ships, a new feature document supersedes the parts of 0014 about where search
  lives; 0014 itself is annotated, not rewritten.
