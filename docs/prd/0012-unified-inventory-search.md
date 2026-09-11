# 0012 — La recherche unifiée, dans l'écran d'inventaire

Maquettes : section `Recherche unifiée` (`334:8624`) du fichier Figma, dix frames + panneau de
spécification — voir [figma-library.md](../design-system/figma-library.md), passe du 2026-09-11.

## Problem Statement

Chercher un livre dans Ex-libris demande de savoir **où** chercher, et la réponse n'est jamais la
même.

Il y a deux recherches dans l'app. Celle de l'onglet Inventaire ne cherche que dans mes propres
livres, et se contente de filtrer la liste déjà chargée. Celle de l'onglet Recherche cherche dans
l'inventaire de mes amis et sur inventaire.io, mais pas dans le mien. Un utilisateur qui tape
« monte cristo » dans l'un ne trouve pas ce que l'autre lui aurait donné, et rien à l'écran ne dit
laquelle des deux il utilise.

Ce que ça coûte, concrètement :

- je cherche un livre que je possède, je passe par l'onglet Recherche par habitude, et je ne le
  trouve pas — l'app me propose de l'ajouter à un inventaire où il est déjà ;
- je cherche un livre à emprunter à un ami, je suis dans l'onglet Inventaire, et j'obtiens une
  liste vide alors que le livre est à deux rues de là ;
- la recherche distante ne part qu'à partir de trois caractères, mais rien ne me le dit : entre un
  et deux caractères, l'écran a l'air cassé ;
- une barre d'onglets porte un onglet entier (« Recherche ») pour une fonction que tout le monde
  attend dans la liste qu'il est en train de regarder ;
- depuis iOS 26, la barre d'outils de cet onglet est masquée, ce qui a déjà déplacé l'entrée du
  scanner et compliqué le scénario end-to-end (commentaire dans `E2EScenarioTests`, étape 4).

Rien de tout cela n'est un bug isolé : c'est la conséquence d'avoir deux recherches qui ne se
parlent pas.

## Solution

**Une seule recherche, dans l'écran d'inventaire, en trois temps** — le modèle de Mail sur iOS.
L'onglet Recherche disparaît.

1. **Au focus du champ** — mes recherches récentes, les trois dernières. Rien d'autre. Quand je
   n'en ai aucune, un état vide le dit : « Aucune recherche récente / Vos recherches récentes
   apparaîtront ici. »
2. **Dès trois caractères** — deux sections. D'abord ce que l'app a déjà sous la main : mes livres
   et ceux de mes amis qui correspondent, **plafonnés à trois**, avec « Tout voir » si la liste
   est plus longue. Ensuite trois suggestions pour aller plus loin sur inventaire.io : « Livres
   contenant *mont* » (glyphe livre), « Auteur·ices contenant *mont* » (glyphe plume), et
   « *mont* » brut (glyphe loupe).
3. **À l'envoi** — touche « rechercher » du clavier, ou tap sur une suggestion : l'appel réseau
   part, les résultats complets s'affichent groupés par type (Livres, Auteur·ices), et la requête
   entre dans mes récentes.

Le reste découle :

- **« Annuler » referme le mode recherche** et ramène à l'inventaire. Il ne vide pas le champ —
  c'est le `xmark.circle` dans le champ qui fait ça.
- **Toutes les requêtes envoyées sont gardées**, localement, sur cet appareil. Trois sont
  affichées ; « Effacer » vide tout et ramène à l'état vide. Pas de suppression unitaire pour
  l'instant.
- **Le seuil reste à trois caractères**, comme aujourd'hui côté réseau — mais cette fois l'écran
  s'accorde avec lui : sous trois caractères, ce sont les récentes qui restent affichées, pas une
  section vide.
- **Le scan ne bouge pas.** Il est déjà dans la barre de navigation de l'inventaire, avec
  « Ranger ».

## User Stories

1. As a lecteur, I want a single search field in my inventory screen, so that I never have to
   choose which of two searches will find what I am looking for.
2. As a lecteur, I want my own books to appear in that search, so that I stop being offered to add
   a book I already own.
3. As a lecteur, I want my friends' copies to appear in the same list, so that I can see at a
   glance whether to buy a book or ask for it.
4. As a lecteur, I want a friend's copy to name its owner, so that I know who to ask.
5. As a lecteur, I want the search to reach inventaire.io when my own shelves come up short, so
   that one field answers every question about a book.
6. As a lecteur, I want to see my last searches the moment I focus the field, so that repeating a
   search costs one tap instead of retyping it.
7. As a lecteur, I want a search I only typed and abandoned to leave no trace, so that my recent
   searches are a list of things I actually looked for.
8. As a lecteur, I want an explicit empty state when I have no recent search, so that a blank
   screen behind the keyboard does not read as a bug.
9. As a lecteur, I want that empty state to look like the rest of the app's empty states, so that
   the app feels made by one hand.
10. As a lecteur, I want « Effacer » next to my recent searches, so that I can wipe them without
    hunting through settings.
11. As a lecteur, I want the local results capped at three, so that the way to inventaire.io is
    never pushed below the keyboard.
12. As a lecteur, I want a « Tout voir » action when my library holds more than three matches, so
    that the cap never hides books from me.
13. As a lecteur, I want my own books listed before my friends' ones, so that the list answers
    "do I own this?" first.
14. As a lecteur, I want the three inventaire.io suggestions to name what they will search, so
    that I choose between books and authors before spending a network call.
15. As a lecteur, I want my typed query shown in bold inside each suggestion, so that I can see
    what will be sent.
16. As a lecteur, I want a plain « *ma requête* » suggestion, so that I can search everything at
    once when I do not know whether I am after a title or an author.
17. As a lecteur, I want tapping a suggestion to run the search immediately, so that a suggestion
    is a shortcut and not a second form to fill.
18. As a lecteur, I want the keyboard's « rechercher » key to run the same search, so that the
    habit I have from every other iOS app works here.
19. As a lecteur, I want full results grouped by type, so that a list of works is not interleaved
    with a list of people.
20. As a lecteur, I want each group to state how many results it holds, so that I know whether to
    refine the query.
21. As a lecteur, I want tapping a work to open its book detail, so that search leads somewhere
    rather than ending.
22. As a lecteur, I want tapping an auteur·ice to open their page, so that I can browse what else
    they wrote.
23. As a lecteur, I want tapping one of my own books to open the copy I own, so that I land on my
    copy and not on an abstract edition.
24. As a lecteur, I want « Annuler » to take me back to my shelves, so that leaving search is one
    tap and does not lose my place.
25. As a lecteur, I want the `xmark.circle` in the field to clear my query without leaving search,
    so that correcting a typo does not close the screen.
26. As a lecteur, I want the search to feel instant on my own books, so that filtering my library
    never waits on the network.
27. As a lecteur, I want a network failure to say so without emptying the local results I can
    already see, so that a dead connection does not look like an empty library.
28. As a lecteur, I want a visible sign that the remote search is running, so that I do not tap
    again thinking nothing happened.
29. As a lecteur, I want a clear message when inventaire.io returns nothing, so that I can tell
    "no result" from "not loaded".
30. As a lecteur, I want typing to stop and restart the network call as I refine, so that I do not
    pay for a search I have already replaced.
31. As a lecteur, I want the search field to say what it searches ("Livre, auteur·ice, ami·e…"),
    so that the merged scope is stated rather than guessed.
32. As a lecteur, I want three tabs instead of four, so that the bar shows only places, not
    actions.
33. As a lecteur, I want the scan button to stay exactly where it is in the inventory, so that the
    merge does not move the one thing I use most.
34. As a lecteur, I want my recent searches to stay on this device, so that what I look for is not
    published with my inventory.
35. As a lecteur, I want my recent searches tied to my account, so that a phone shared with
    someone else does not mix our histories.
36. As a lecteur, I want my recent searches to survive quitting the app, so that a list of "last
    searches" means something.
37. As a lecteur, I want searching the same thing twice not to duplicate the entry, so that three
    slots show three different searches.
38. As a lecteur, I want accents and case ignored when matching my books, so that "emile zola"
    finds « Émile Zola ».
39. As a lecteur searching in the dark, I want every state of this screen to be legible in dark
    mode, so that the merge does not introduce the app's first light-only screen.
40. As a lecteur using large text, I want the rows to grow with Dynamic Type, so that the
    suggestions stay readable.
41. As a lecteur using VoiceOver, I want each row to announce what it will do (a recent search, a
    book search, an author search), so that three rows carrying the same query are
    distinguishable.
42. As a développeur, I want the threshold, the phases and the cap to live in one pure type, so
    that the rule cannot drift between the view that shows and the model that fetches.
43. As a développeur, I want the recent-search store to be testable with its own `UserDefaults`,
    so that a test never writes into the running app's domain.
44. As a développeur, I want the dead `SearchModel.searchLocalInventory` finally used or removed,
    so that the search layer has no unused entry point.
45. As a développeur, I want the end-to-end scenario updated in the same batch, so that the merge
    does not leave a red step behind it.
46. As a QA, I want the e2e accessibility identifiers to keep naming the same things, so that the
    compte-rendu stays comparable from one run to the next.

## Implementation Decisions

### The three deep modules

**`SearchPhase`** — a pure value type in `Model/SearchResult/` that answers "what does this screen
show right now?" from three inputs: whether the field is focused, the trimmed query, and whether a
search has been submitted for that query. Cases: `recents`, `typing(query)` (one or two
characters — the recents stay on screen), `suggesting(query)` (three or more), `results(query)`.
It owns the three-character threshold, and it owns the rule that submitting moves to `results`
while editing the query moves back out of it. No view and no model duplicates that arithmetic.
Prior art for shape and tests: `BatchScanStateMachine`, `TransactionStateMachine`.

**`RecentSearchStore`** — `AppModels/Search/`, `@MainActor @Observable`, built exactly like
`OnboardingStore`: an observed property mirrored into an injectable `UserDefaults`, keyed **per
user `_id`** so a shared device keeps two histories apart and signing out erases nothing. Surface:
the whole ordered history for a user, `record(query:userId:)`, `clear(userId:)`, and the
three-item slice the screen displays. `record` normalises (trim, collapse whitespace) and
de-duplicates case- and diacritic-insensitively, moving an existing entry to the front rather than
appending a twin. **No cap on what is stored** — the cap is a display concern, three rows.
Recorded only on submit, never on keystroke.

**`InventorySearchRanking`** — a pure function in `Model/SearchResult/` over lightweight value
inputs (an id, a `searchIndex`, an `isMine` flag, a creation date) rather than over
`InventoryItem`, so it is testable without a `ModelContainer`. Filters with the app's
`localizedStandardContains` rule, then orders **mine before friends'**, most recently added first
within each group, and returns both the capped three and the total count — the count is what
decides whether « Tout voir » appears.

**`SearchSuggestion`** — a pure value type: from a query of three or more characters, the three
suggestions (works, humans, raw) with their glyph and localisation key. The mapping from a
suggestion to the API call it triggers (`types=works` / `types=humans` / `types=humans|works`)
lives here too, so the row and the request cannot disagree.

### Views

- `ShelvesContent`'s `isSearching` branch — today a flat list of the user's own books — is
  replaced by a search surface driven by `SearchPhase`. `ShelvesView` keeps `.searchable`, gains
  the merged prompt, an `.onSubmit(of: .search)` that records the query and submits, and the
  search-dismiss behaviour for « Annuler ».
- New rows mirroring the Figma components: a query row used **twice** (a recent search with a
  clock glyph, a suggestion with a book/plume/loupe glyph and the query in bold) — one view, not
  two.
- **The empty state is the app's first real one.** There is no generic empty-state view in the
  code today: every empty list draws its own centred `Text`, which is exactly what the états-vides
  pass of 2026-08-28 documented and proposed to replace (`Empty State` `204:263`,
  `Layout=Centered`). This screen implements that proposal as a reusable view — glyph, title,
  sentence, optional action — so the four other empty states can adopt it afterwards instead of
  each growing a variant of the same block.
- Local results reuse `InventoryCell`; remote results reuse `SearchResultCell` (`Cell / Entity` in
  Figma), which already serves works, humans and owned items.
- Navigation keeps going through `NavigationDestination` and the inventory tab's own
  `NavigationPath`; no new stack, no new destination case unless « Tout voir » gets its own screen
  (see Out of Scope).

### Deletions and their fallout

- `MainTabView`: the `.search` tab, its `TabConfig` case and its `TabRole.search` go. The bar
  drops to three visible tabs.
- `MainSearchView` and `SearchView` are deleted. `SearchResultCell` and `SearchModel` survive.
- `SearchModel.searchLocalInventory` — dead today — is either the source of the local section or
  it is removed; it does not stay unused. Preference: remove it, because the local section reads
  the same `@Query`-backed items the inventory already has, and going through a second fetch would
  break the reactivity ADR 0001 asks for.
- **The end-to-end scenario breaks in three places** and is fixed in the same batch:
  `openTab(.search)`, `popBack(to: .search)`, and `E2EDriver.Tab.search`. The three searches of
  the scenario now run from the inventory tab's field. Read
  [feature 0012](../features/0012-end-to-end-scenario.md) before touching it; keep
  `e2e.searchResult` naming the same thing so past compte-rendus stay comparable, and add
  identifiers for the new rows (recent, suggestion) rather than reusing it.

### Data flow

Local results come from the existing reactive `@Query` over `InventoryItem` — mine by owner id,
friends' by its negation — filtered in memory by `InventorySearchRanking`. Nothing new is
persisted about books. The remote call stays `SearchModel.searchEntity`, debounced, its in-flight
`Task` cancelled when the query changes, its failure surfaced through `AppErrorReporter` the way
every other model does. ADR 0001 is untouched: nothing here writes to the server, so nothing here
is optimistic.

`RecentSearchStore` is created in `RootView` alongside the other app models and injected into the
environment, per the project's one rule about shared models (built and injected in both places).

### Copy

French, vouvoiement — the app's rule. The new strings go into `Localizable.xcstrings`: the field
prompt, the two section headers, « Effacer », « Tout voir », the three suggestion labels (with the
query interpolated), and the empty state's title and body. The local section is titled from the
first person (« Dans mes livres et chez mes amis ») rather than reusing
`search.friends_inventory`, which is the catalogue's only tutoiement — that string dies with
`SearchView`.

## Testing Decisions

Tests only on the modules that can be tested without a screen. A good test here drives the
**public surface** of a type and asserts what a user would notice — which phase the screen is in,
which three books come back and in what order, what the history contains after two searches. None
of them reaches into a private property, and none of them asserts that a particular view exists.
Swift Testing (`@Suite` / `@Test`), in `Tests/`, no network.

**Tested:**

- `SearchPhase` — the threshold (zero, one, two, three characters), the transition on submit and
  the return to `suggesting` when the query is edited afterwards, what a whitespace-only query
  does, and what happens when the field loses focus. Prior art:
  `BatchScanStateMachineTests`, `TransactionStateMachineTests`.
- `RecentSearchStore` — empty at first; a recorded search comes back; two users on one device keep
  separate histories; a history survives a new store over the same defaults; a repeated search
  moves to the front instead of duplicating; case and accents fold together; nothing is stored on
  a query that was never submitted; `clear` empties one user without touching the other. Each case
  gets its own `UserDefaults` suite, never `.standard`. Prior art: `OnboardingStoreTests`,
  which exists for exactly these launch-shaped failures.
- `InventorySearchRanking` — the cap at three with the total still reported; mine before friends';
  ordering within a group; accent- and case-insensitive matching; an empty query; a query matching
  nothing.
- `SearchSuggestion` — three suggestions in a stable order, each carrying the right entity types
  for the request.

**Not tested:** the SwiftUI views, `.searchable` behaviour, and the navigation from a result —
covered by the end-to-end scenario, which is updated as part of this work and is the only place
this project drives the real screens.

## Out of Scope

- **Deleting one recent search.** Everything is kept, « Effacer » wipes all of it. Per-entry
  removal, and any cap on the stored history, come later.
- **Syncing recents with the account.** They stay on the device.
- **Search scopes.** The `Search / Scope Card` component exists in Figma and is parked with no
  instance: choosing "search only my books" / "only my friends'" is a later question, and the
  maquette assumes the scope is a starting point, not a persistent filter.
- **« Tout voir ».** It appears in the maquette; where it leads — a dedicated screen, or the
  inventory list already filtered — is not decided here.
- **The three-tab tab bar in Figma.** The onglet Recherche is hidden as an instance override in
  the maquettes; a real `Chrome / Tab Bar` variant is a design-file chore, not a product decision.
- **"No result for this query", loading, and network error.** The empty state in this PRD is about
  *recents* being empty. The no-result case already has a maquette of its own from the états-vides
  pass — « C · Recherche sans résultat », proposed frames `211:6605` / `211:6686`, against
  `InventoryListContent` — and adopting it is a follow-up that becomes cheap once the reusable
  empty-state view exists. Loading and error keep whatever the current search shows, minus the
  unlocalised string.
- **Searching étagères, listes or users.** Books and people on inventaire.io, plus the local
  inventory. Nothing else joins the field.
- **Voice search and barcode from the field.** The scan stays where it is, in the navigation bar.

## Further Notes

The merge closes a divergence rather than opening one: `SearchModel.searchLocalInventory` was
written for exactly this screen and has never been called (`D-R1` in the Figma library's
divergence table). Two others in the same table die with `SearchView` — the unlocalised
« loading more results... » (`D19` / `D-R3`) and the `Button` wrapping a
`NavigationLink(value: UUID())` whose only job is to draw a chevron (`D-R5`).

One thing the maquettes cannot show and the implementation has to respect: **the keyboard covers
everything below roughly 516 pt.** Every state of this screen has to say what it has to say in the
band between the search field and the keyboard. That is the reason the local results are capped at
three rather than scrolling — below three, the road to inventaire.io disappears under the
keyboard, and the second half of the feature becomes invisible.

The last open point is the tab bar: iOS 26 already hides the search tab's toolbar, which is what
pushed the scanner's entry point into the inventory's navigation bar. Removing the tab removes the
last reason to care about that behaviour.
