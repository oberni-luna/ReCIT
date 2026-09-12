# Unified search, in the inventory screen

Shipped on 2026-09-11 from PRD `docs/prd/0012-unified-inventory-search.md` (deleted — see
`docs/prd/README.md`). Seven issues, 0070 to 0076.

Note on numbering: this document is `0014` and not `0012`. Feature documents carry their own
sequence, and `0012` was already taken by [the end-to-end scenario](0012-end-to-end-scenario.md).
The PRD number and the feature number do not line up for this one.

## What it does

There used to be two searches that did not speak to each other: the inventory tab filtered only
your own books, the Recherche tab searched inventaire.io and your friends but never your own
shelves, and nothing on screen said which one you were using. There is now one field, in the
inventory screen, and the Recherche tab is gone.

It answers in three movements, on the model of Mail. Focus the field and your last three searches
come back. Type three characters and you get what the app already has under its hand — your books
and your friends', capped at three, yours first — followed by three ways on to inventaire.io:
books containing your query, authors containing it, or the query on its own. Submit, by the
keyboard's « rechercher » key or by tapping a suggestion, and the full results arrive grouped by
type, with the query joining your recent searches.

Under the cap, « Tout voir » opens a screen listing every local match. When the remote call brings
nothing back, the screen says which kind of nothing it is: still loading, no result, or a failure
you can retry — and a failure never hides the books already on the device.

## Technical surface

**Pure modules** (`Model/SearchResult/`), all testable without a `ModelContainer`:

- `SearchPhase` — the screen's state machine (`recents` / `typing` / `suggesting` / `results`),
  and **the app's only copy of the three-character threshold**. Before it, the number lived in
  `SearchView` and disagreed with the screen, which is why one and two characters looked broken.
- `InventorySearchRanking` — filters with `localizedStandardContains`, orders mine before
  friends' and most recently added first within each group, and returns the capped slice **and**
  the uncapped total. `+InventoryItems` carries the single `[InventoryItem]` → ranked translation.
- `SearchSuggestion` — the three suggestions, each carrying the entity types of its API request,
  so a row and the call it fires cannot diverge.
- `RemoteSearchState` — `idle / loading / loaded / failed`, whose `sign` returns **at most one**
  of loading / no-result / failure. `.loaded([])` is deliberately a different value from `.idle`.

**Stores** — `AppModels/Search/RecentSearchStore`, shaped like `OnboardingStore`: observed
property mirrored into an injectable `UserDefaults`, keyed per user `_id`. Built in `RootView` and
injected into the environment.

**Screens** — `Features/Inventory/InventorySearch*` (content, local section and its header, the
suggestions section, the results section and group, the recents section, the all-local screen) and
the shared `SearchQueryRow`, which serves a recent search and a suggestion alike. `EmptyStateView`
in `Features/Components/` is the app's first reusable empty state.

**Navigation** — one new `NavigationDestination` case, `localSearchResults(query:)`, pushed onto
the Inventory tab's own path. No new stack.

**Deleted** — the `.search` tab, its `TabConfig` case, the whole `TabRole` property,
`MainSearchView`, `SearchView`, `SearchModel.searchLocalInventory`, and eight orphaned catalogue
keys. `SearchResultCell` and `SearchModel` survive.

Nothing new is persisted about books, and nothing here writes to the server, so nothing here is
optimistic. ADR 0001 is untouched.

## Notable decisions

- **The cap of three is a display rule, not a search rule.** The keyboard covers everything below
  roughly 516 pt, and a fourth row would push the road to inventaire.io under it. The uncapped
  total comes back alongside, which is what decides whether « Tout voir » appears.
- **« Tout voir » opens a dedicated pushed screen**, chosen by the owner over a filtered inventory
  (which loses the suggestions and the friends' copies) and over unfolding in place (which puts
  inventaire.io back under the keyboard). Both surfaces call one ranking function differing only
  by `limit`, so the screen opens on exactly the three the section showed and carries on.
- **Recents are recorded on submit only**, never on a keystroke, which is what makes the list a
  list of things actually looked for. Everything is stored, uncapped; three are displayed.
  Per-entry deletion does not exist — « Effacer » wipes all of it.
- **The empty-recents state and the no-result state are two different states** with two different
  sets of keys. Neither text is reused for the other.
- **The empty state drops the `List` rather than adding a row to it.** A `List` keeps its full
  height under the keyboard and insets its content, so a row centred inside it lands behind the
  keys. A plain container is laid out inside the safe area, and the keyboard *is* a bottom
  safe-area inset — which lands on the mock's placement with no magic number.
- **Retry re-keys the existing `.task`** rather than opening a second path to the network.
- **An answered query is not asked again** (2026-09-11). SwiftUI cancels a `.task` when its view
  goes off screen and runs it again when the view comes back, so opening a result and pressing
  Back re-entered `search()`: the screen discarded an answer it already had, showed the loading
  row, and asked inventaire.io the same thing a second time. Every book looked at cost a round
  trip, and the list flickered on the way back. `InventorySearchContent.answered` records the
  attempt whose answer is on screen — results, emptiness and failure alike — and `search()`
  returns early when the standing attempt is that one. Verified on the simulator against the
  live server by counting `GET /api/search` in the app's `asso.recits:network` log: a
  search → book → Back cycle logs **0** requests, a new query logs **1**.
- **Refreshing became a gesture, because it had stopped being an accident.** With the line above
  in place there was no way left to ask the same question twice: re-sending an identical query
  produces an identical attempt, and « Réessayer » only appears on failure. The results list
  therefore carries its own `.refreshable`, which bumps the attempt — innermost of the app's two,
  so a pull *on the search results* refreshes the search rather than the shelves that
  `RootView`'s one refreshes. It does not call out itself: there is exactly one place a call
  leaves this screen. Verified the same way — one pull, one request.
- **`e2e.searchResult` still names a remote result**, so compte-rendus stay comparable across the
  merge. The new rows carry their own identifiers.

## Owed, and known

- **Two Figma frames.** The `Recherche unifiée` section has none for the « Tout voir » screen, nor
  for the loading and failure states. The three-tab `Chrome / Tab Bar` variant stopped being a
  documented shortcut and became a real gap the moment issue 0074 deleted the tab.
- **`scripts/e2e.sh` has not been run against this.** The scenario compiles (`ReCIT_iOSE2E`
  builds) and its three search steps were rewritten to drive the inventory field, but the run
  itself is the human step of issue 0074 and is still outstanding.
- **Divergence D-R5 stays open.** Issue 0074's criterion said it would die with `SearchView`; it
  did not. The `Button` wrapping a `NavigationLink(value: UUID())` survives in eight other files,
  two of which are the rows the e2e scenario already documents as needing two aim points.
- **`SearchResultCell.swift:59`** interpolates an unlocalised English fallback
  (`"someone, somewhere"`) inside a localised key. Pre-existing, on the search path, left alone
  because fixing it is a copy decision.

## Issues

- `docs/issues/0070-local-search-section-and-threshold.md` — the local section and the threshold — 229d0a9
- `docs/issues/0071-inventaire-io-suggestions-and-results.md` — three suggestions, and the full results — fda1ee3
- `docs/issues/0072-recent-searches-kept-locally.md` — recent searches, kept on the device — b51b661
- `docs/issues/0073-reusable-empty-state-view.md` — the reusable empty state — c5921e5
- `docs/issues/0074-retire-the-search-tab.md` — the Recherche tab retires — e76a65d
- `docs/issues/0075-see-all-local-matches.md` — « Tout voir » — 90ba788
- `docs/issues/0076-search-loading-no-result-and-error-states.md` — loading, no result, error — 2126c61
