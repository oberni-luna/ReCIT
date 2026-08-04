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

Two independent moves, ordered. Presentation layer only — we do **not** collapse the SwiftData
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

## Consequences

- New: `BookAnchor`, `BookViewModel`, `BookDetailView` (+ folded section sub-views), and later
  `WorkEditionGatewayView`, under `Features/EntityBrowser/` (or a new `Features/Book/`).
- Move 1 and Move 2 ship independently. Move 1 (Edition⊕Item) alone already removes one of the
  three screens; Move 2 can wait or be dropped without stranding Move 1.
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
