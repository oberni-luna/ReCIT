# ADR 0002 — One "book" screen over Work / Edition / InventoryItem

- Status: Accepted
- Date: 2026-08-04

## Context

Today a "book" is presented through **three** separate detail screens, each a distinct
`NavigationDestination` case:

- `WorkDetailView` (`.work(uri:)`) — the abstract work; loads the work and lists its editions.
- `EditionDetailView` (`.edition(uri:)`) — one specific edition; who owns it + my copies.
- `InventoryItemDetailView` (`.item(item:)`) — my physical copy; notes, transactions, owner.

These mirror the server's `inventaire.io` entity hierarchy, which the app treats as identity
truth (`_id`/`_rev`, `uri`):

```
Work  n──n  Edition  1──n  InventoryItem          Author n──n Work
(œuvre)      (édition)       (mon exemplaire)
```

The Work↔Edition link is **n──n, not 1──n**: one edition can bundle several works. Real
example: edition `inv:049a5d616589c7d82d7e3ca3e0be2993` ("Histoire de moine et de robots") is
a single French book that references **two** works via `wdt:P629` (the two Monk & Robot
novellas by Becky Chambers). Omnibus, recueil, and paired-novella editions are common. There
is therefore **no single parent work** to resolve an edition up to.

The problem is that this is a **data-model distinction leaking into the UX**. A user says
"livre" and does not care about work-vs-edition until a concrete need arises (two
translations, a specific cover). They *always* care about "is it mine / can I lend it". Three
screens for one intuitive object forces the user to hold a taxonomy the domain imposes, not
one they asked for. Navigation also fans out into three destinations that push into each
other (`item → work`, `edition → item`, `work → edition`), so the same book is reachable at
three different "depths" of the same stack.

## Decision

Three independent moves, ordered. Move 3 was added on 2026-09-11. Presentation layer only — we do **not** collapse the SwiftData
models; the server owns Work/Edition/Item identity and ADR 0001's invariants depend on those
objects keeping it. The Work↔Edition n──n relation stays exactly as modelled.

### Move 1 — merge Edition + Item into one "book" screen

The thing a user holds, owns, lends, gives, or sells is the **Edition**. An `InventoryItem` is
just "my copy of that edition" — it is not a separate object worth its own screen. So Edition
and Item collapse into a single `BookDetailView` **anchored on an Edition**, with the owned copy
folded in as an overlay:

```swift
enum BookAnchor: Hashable {
    case edition(uri: String)   // arrived from search, a list, a work gateway…
    case item(InventoryItem)    // arrived from my inventory → resolves to item.edition
}
```

Both anchors resolve to one Edition. `.item` simply reads `item.edition`. The screen renders
the edition, plus the ownership overlay when I own a copy.

`BookViewModel` (`@Observable @MainActor`, ADR 0001 invariant 1) holds:

- `edition: Edition` — the resolved edition (present once loaded).
- `myItems: [InventoryItem]` — my copies of this edition, sourced reactively (`@Query` scoped by
  edition + current user) so optimistic writes and background syncs keep the overlay live.

The model exposes behavior only (`Void`/`throws`); the view renders from SwiftData. Loading is a
`ViewState` enum unifying the two old screens' ad-hoc states.

**Sections** — one header + summary + authors (the already-shared `EntityHeaderView`,
`EntitySummaryView`, `EntityAuthorsView`, `EntityImageView`), then:

- **Œuvres** — the edition's `works` (1..N). Always present; for a single-work edition it is a
  one-line "d'après <œuvre>", for an omnibus it lists all of them. Each links to that work's
  gateway (Move 2). Header authors are the **union** of every work's authors — `Edition.authors`
  already computes this, so the multi-work case needs no model change.
- **"Ton exemplaire"** — only when `myItems` is non-empty. Folds in the current
  `InventoryItemDetailView` content: notes editing, transaction picker, owner. Stays on a
  `@Bindable InventoryItem` (needs the two-way picker binding; optimistic writes must survive
  the fold — ADR 0001 invariant 3).
- **Communauté** — who else has this edition.
- **Listes** — as today.

Edge case: an item whose `edition` is not yet hydrated → resolve to a loading state, fetch, then
upsert-in-place (ADR 0001 invariant 2). Never delete+reinsert the object a view is showing.

### Move 2 — Work becomes a conditional edition gateway, not a screen

A Work is not a book you can hold; it is a text that exists in 1..M editions. So the Work view
stops being a destination and becomes a **router to editions**:

- **1 edition → the work never shows.** Navigating to the work forwards straight to
  `.book(.edition(uri))`, replacing itself in the path so Back skips it.
- **>1 edition → a thin picker.** The work renders a chooser ("Quelle édition ?" — cover /
  publisher / year / language per edition); tapping one pushes `.book(.edition(uri))`.

Because edition count is only known after a fetch, the gateway owns that decision at runtime:
load editions → if exactly one, forward; else render the picker. From the user's side, a
single-edition work is invisible; a multi-edition work is a one-tap disambiguation.

### Navigation

Add the book destination; the work destination stays but points at the gateway:

```swift
case book(anchor: BookAnchor)   // id: "book:\(anchor.stableId)"  → BookDetailView
// case work(uri:) stays, now → WorkEditionGatewayView (forwards or picks)
// case edition(uri:) / case item(item:) are retired once nothing pushes them
```

Author detail is **out of scope** — an author is not a book; `.author` stays as-is.

### Move 3 — a search result resolves to an edition, not to a work

`/api/search` cannot return editions. Verified against the live server:

```
invalid types: editions (possible values: works, humans, genres, publishers,
series, collections, movements, languages, users, groups, shelves, lists)
```

So a search for a book returns **works**, and the only route to a holdable book is to resolve a
work's editions client-side. Today that resolution is the user's job: tapping a result lands on
`WorkEditionPicker`, which asks which of the 66 editions of *Dune* they meant — a question nobody
has the information to answer, asked at the exact moment they were looking for a book.

**A search result therefore resolves to the single most relevant edition, at tap.** Not in the
list: resolving one work costs ~750 ms and ~60 KB (`reverse-claims` then `by-uris`, measured), and
`reverse-claims` ignores `limit`, so the full edition list always comes back. Fifteen results would
be thirty requests and ~900 KB per search, most of it for rows nobody scrolls to. The list keeps
rendering the work's `lang=fr` label and cover — which the search already returns — and the section
header already reads « Livres · N », not « Œuvres ». This move makes that label true rather than
aspirational.

A third anchor case carries it:

```swift
case bestEditionOfWork(uri: String, title: String, imageUrl: String?)   // stableId: "work:\(uri)"
```

The title and image are the ones the search result already holds, so the screen opens with its
header filled and only its body loading. `.item` already carries a whole `@Model`, so a display
payload on an anchor is not new, and `stableId` stays derived from the uri alone.

**"Most relevant" is a ladder, not a score.** In order, the first non-empty tier winning:

1. French, titled, with a cover
2. French, titled
3. The work's original language, titled, with a cover
4. Any titled edition

**There is no fifth rung.** An earlier draft ended in a catch-all so that a tap always opened
*something*; that meant a tap could redirect onto a book called `Unknown`, and the owner ruled it
out on 2026-09-11. Running off the end of the ladder is an answer, and the screen renders it.

"Titled" means **having a name on screen**, asked through `EditionTitle` — the single resolution
`Edition` itself uses. It is not the `wdt:P1476` claim, which this ladder consulted at first: the
two disagree for 13 % of editions (66 of 513 sampled), because inventaire.io synthesises
`labels.fromclaims` for its own `inv:` entities while editions mirrored from Wikidata carry their
title under the multilingual `mul` label. Every one of those 66 was ranked as titled and then
drawn as `Unknown`. A rule about what the user sees must be asked of the thing the user sees.

Inside the winning tier, two tie-breaks, in this order.

**A single book before a box of several.** `wdt:P629` names every work an edition is of, so a novel
names one and an omnibus names them all. Searching « Harry Potter et la Chambre des Secrets » opened
*Harry Potter, coffret 4 volumes*: French, named, covered — top rung — and first out of
`reverse-claims`. Handing someone four books when they asked for the second answers a different
question. It narrows rather than excludes: when a whole rung is boxed sets, a boxed set still wins.
Measured before adopting it — across 16 works it changes exactly one winner, the wrong one.

**Then an edition already held by the user or one of their friends** — a free local
`InventoryItem` lookup, no network. Second rather than first, because a copy of my own is already
listed in the search screen's local section; the remote result need not surface it again, and
certainly not as a box. It never lifts an edition **between** tiers: a Spanish copy a friend owns
does not beat twenty French ones.

Two criteria were considered and rejected. "The edition title matches the work label" rejects
`Dune, Tome 1` and every legitimate translation; having a name is the reliable signal, being named
the same thing is not. Publication date and ISBN correlate with the tiers above and add nothing
once they hold.

**Resolution does not go through `EntityModel.getWorkEditions`.** That method inserts every edition
it sees — 127 objects for *1984*, on one tap — resolves each one's works, and saves on the main
actor. Move 3 reads `reverse-claims`, then `by-uris` with a lean `attributes` list, ranks in memory
over DTOs, and persists **only the winner**, through the existing `refreshEdition` (which upserts —
ADR 0001, invariant 2). Nothing else reaches the store.

**The choice is remembered.** `Work.preferredEditionUri` is a local derived field, in the company of
`Work.genres` / `genresEnrichedAt` and `Edition.dominantColorHex` / `numberOfPages` — all local,
none of them server state. A second tap opens from cache. That is also what makes the same gesture
open the same book twice, which a recomputed ranking cannot promise.

**Opening from cache does not excuse the round trip.** The background pass refreshes the edition it
just handed the screen *and* replays the ladder, in that order. Refreshing only when the ranking
moved — which is almost never — was the first draft, and it meant an edition opened from the
preference was never revalidated again: whatever that row held was permanent. The Harry Potter
edition `wd:Q58464836`, cached as `Unknown` by the title mapping that preceded `EditionTitle`, kept
that name on every visit. Invariant 2 of ADR 0001 is not optional because a fast path exists; the
fast path is what makes the revalidation a background concern instead of a wait.

Order of operations, because it is not the obvious one: the search persists nothing, so at tap time
there is no `Work` row to write the preference onto. The `Work` materialises when `refreshEdition`
resolves the winner's `wdt:P629`; the preference is written **there**, not before. No extra
`refreshWork` is needed, and adding one would be a third request for nothing.

**`.work` stays, and stays the picker.** It is what `BookDetailView`'s « Autres éditions » pushes
(`OtherEditionsCell`), and what the lists and the author screen push. Move 3 changes exactly one
push site — `NavigationDestination.destinationForSearchResult` — which has exactly one caller. The
picker's navigation title becomes « Éditions » rather than « Œuvre »: it is now reached only from a
book, and the word two moves spent hiding has no reason to reappear there.

**A tap always answers — which is not the same as always opening a book.** Two outcomes have
nothing to show: a work with no edition at all (`reverse-claims` returns `[]`, as for a ghost
duplicate of *Americanah*), and a work whose every edition is nameless. Today the gateway sits on a
spinner forever in that case — the end-to-end scenario carries a comment saying so, and backtracks
past it. Move 3 pushes the book screen and renders `BookViewModel.ViewState.noResult` as an
`EmptyStateView`, with the network failure as its own text and a retry.

## Consequences

- New: `BookAnchor`, `BookViewModel`, `BookDetailView` (+ folded section sub-views), and later
  `WorkEditionGatewayView`, under `Features/EntityBrowser/` (or a new `Features/Book/`).
- Move 1 and Move 2 ship independently. Move 1 (Edition⊕Item) alone already removes one of the
  three screens; Move 2 can wait or be dropped without stranding Move 1.
- Move 3 ships on top of Move 2 and touches one push site. It adds `EditionRelevance` (a pure,
  testable ranking type under `Model/Books/`), a lean resolution reader that never writes to the
  store, a third `BookAnchor` case, and one additive `Work` field. Nothing about Moves 1 and 2 is
  revisited; reverting Move 3 is reverting one `switch` case in
  `NavigationDestination.destinationForSearchResult`.
- Move 3 is the first place the app chooses *for* the user among server entities. The rule is
  therefore written once, in a type that has no network and no `ModelContext`, so that what the
  app decided is readable without running it.
- No polymorphic focus, no level resolution — the anchor always resolves to an Edition. The
  only runtime branch is the gateway's "1 edition → forward, else pick", isolable and testable.
- `_id`/`_rev`/`uri` identity and all ADR 0001 invariants are untouched — this is a UX change,
  not a data change. The Work↔Edition n──n relation is unchanged.

## Migration (incremental)

### Move 1 — Edition ⊕ Item (done)

- **P1 (done)** — `BookAnchor` + `BookViewModel` (anchor → `edition`, `ownedItemsPredicate`),
  unit-tested. `BookViewModel.load` takes `entityModel` per-call (not via init) so the view can
  build the VM in its own `init` before the environment is available.
- **P2 (done)** — `BookDetailView`: header/summary/authors + **Œuvres** + **Communauté** +
  **Listes**, at parity with the old `EditionDetailView`.
- **P3 (done)** — Folded the item's editable content into `BookMyCopySection` (`@Bindable`
  item): notes, transaction picker, delete. Optimistic transaction/details writes covered by
  `InventoryModelTests`.
- **P4 (done)** — Added `.book(anchor:)`; routed search, scanner, inventory list, community,
  work→edition, and transaction→item through it. `NavigationDestination` and `BookAnchor` carry
  hand-written `==`/`hash` on their id/stableId — synthesized conformance does not compose over
  `@Model` payloads under strict concurrency.
- **P5 (done)** — Deleted `EditionDetailView` / `InventoryItemDetailView` and the `.edition` /
  `.item` cases; rerouted `CommunityView`'s `Edition.self` destination to `BookDetailView`.

Follow-up (done): the "request to borrow" flow (`TransactionFormView`) that the old item screen
exposed for *other people's* copies is back, as a "Emprunter à" submenu in `BookDetailView`'s
toolbar menu — it lists the first five distinct other owners and opens the request form for the
chosen one.

### Move 2 — Work as edition gateway (done)

- **P6 (done)** — `WorkEditionGatewayView` loads the work's editions, then: exactly one edition
  → renders `BookDetailView` inline (so there is no separate work screen and Back returns to the
  caller); more than one → `WorkEditionPicker` (work header + editions list). Rendering the book
  inline achieves the intended "Back skips the gateway" UX without mutating the `NavigationPath`.
- **P7 (done)** — `.work(uri)` now resolves to `WorkEditionGatewayView`; the old `WorkDetailView`
  is deleted. Push-sites were left untouched — they already push `.work`, which the gateway sits
  behind, so no caller needed rewiring.

### Move 3 — a search result resolves to an edition (to do)

Specified in [PRD 0014](../prd/0014-search-results-are-editions.md), broken down in issues 0083 to
0088. The order is the order of the ladder: the rule first, in a type that can be proven without a
simulator; then the reader that feeds it; then the tap that uses it; then the two absences, the
memory, and the end-to-end scenario.
