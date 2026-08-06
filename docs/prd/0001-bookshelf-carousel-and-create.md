# PRD — Bookshelf carousel & shelf creation

Status: needs-triage
Area: Inventory / Étagères (see ADR 0003)

## Problem Statement

The bookshelf inventory screen shows the user's étagères (shelves) as a fixed 2-up
vertical grid of small shelves. Shelves are cramped — only a few books fit before
switching to a pile — and the grid grows tall as shelves multiply, pushing the rest of
the inventory off-screen. The user also has no way to create a new shelf from the app:
shelves can only be made on inventaire.io. The user wants larger, better-filled shelves,
a compact way to browse many of them, and to create a shelf without leaving the app.

## Solution

Replace the 2-up grid with a horizontal, snapping **carousel** of larger shelf cards.
Each shelf is wide enough to hold many books and lays them out "mixed" (spines that fall
back to a half-and-half spines+pile arrangement when they overflow). At the end of the
carousel sits an empty "create" shelf with a **+** button that opens a small form to
create a new étagère (name + optional description), written to inventaire.io. The full
"Tous les livres" list stays below the carousel. Vertical page height stays bounded
because the carousel scrolls horizontally.

## User Stories

1. As a RECITs collector, I want my shelves shown as large cards in a horizontal
   carousel, so that each shelf can display many of my books.
2. As a collector, I want to swipe the carousel sideways to move between shelves, so that
   many shelves don't consume vertical space.
3. As a collector, I want each swipe to snap to a shelf card, so that a shelf is always
   framed cleanly rather than cut off at the screen edge.
4. As a collector, I want the next shelf to peek at the screen edge, so that I can tell
   there are more shelves to scroll to.
5. As a collector, I want my shelves ordered alphabetically, so that I can predict where
   each one is.
6. As a collector, I want a book count and clear titles ("Étagères", "Tous les livres"),
   so that I understand the screen's structure.
7. As a collector, I want the "Tous les livres" list to remain below the carousel, so
   that I still have a flat list of everything I own.
8. As a collector with a shelf holding a single book, I want that book shown face-on with
   its real cover, so that the shelf looks intentional and attractive.
9. As a collector whose books all fit on a shelf, I want them all standing as spines with
   the last one leaning realistically, so that the shelf mimics a real bookcase.
10. As a collector whose books overflow a shelf, I want the left half filled with standing
    spines and the right half with a horizontal pile, so that all previewed books are
    visible without an oversized shelf.
11. As a collector, I want a book's spine thickness to reflect its real page count, so
    that thick and thin books look different, as on a real shelf.
12. As a collector, I want a lying book's thickness and length to vary too, so that piles
    look natural.
13. As a collector, I want the books zone height bounded to a 9/16 ratio of the shelf
    width, so that shelves keep a consistent, pleasant proportion.
14. As a collector, I want the painted spine tinted by the cover's dominant colour, so
    that shelves are colourful and recognisable.
15. As a collector, I want to tap a shelf to open its full list of books, so that I can
    browse a shelf beyond its preview.
16. As a collector, I want to press-and-hold then slide across a shelf's books to scrub
    through them (each zooming with a haptic tick), so that I can pick a specific book
    quickly.
17. As a collector, I want a plain horizontal swipe to scroll the carousel rather than
    scrub, so that the two gestures don't conflict.
18. As a collector, I want releasing a scrub on a book to open that book, so that I reach
    a book in one gesture.
19. As a collector, I want sliding off a shelf during a scrub to cancel the selection and
    do nothing on release, so that I can bail out of an accidental scrub.
20. As a collector, I want a book's cover colour and page count to load in the background
    and be remembered, so that shelves fill in quickly and don't refetch.
21. As a collector, I want an empty "create" shelf card at the end of the carousel with a
    large + button, so that creating a shelf feels like adding to my bookcase.
22. As a collector, I want tapping the + to open a small form (name, optional
    description), so that I can name my new shelf.
23. As a collector, I want my new shelf to appear immediately (optimistically) while it
    saves to the server, so that the app feels instant.
24. As a collector, I want a failed shelf creation to be surfaced and rolled back, so that
    I'm not misled into thinking a shelf exists when it doesn't.
25. As a collector, I want new shelves to default to private visibility, so that I don't
    accidentally publish a shelf.
26. As a collector, I want the newly created (empty) shelf to slot into the alphabetical
    order, so that it's where I'd expect it.
27. As a collector, I want to search my inventory from this screen, and have the shelves
    hidden while searching, so that search results aren't cluttered by the carousel.
28. As a collector, I want tapping a book in "Tous les livres" to open that book, so that
    the flat list behaves like a standard inventory list.
29. As a collector using VoiceOver / larger text, I want the shelf titles and controls to
    respect Dynamic Type, so that the screen stays usable.

## Implementation Decisions

- **New pure module `ShelfBooksLayout`** — extracts the "mixte" layout math from the
  SwiftUI view. Input: the ordered book list's page counts (optional per book) and the
  shelf's usable width and zone height. Output: a layout plan — one of `singleCover`,
  `allVertical`, or `mixed(verticalCount:)` — plus derived per-book geometry (spine
  thickness = pages ÷ 15, default 20, clamped; spine heights via deterministic variance;
  lean offset for the last standing book = previousHeight · tan(θ); pile bar thickness
  and fit-scaling). The SwiftUI `ShelfBooksView` becomes a thin renderer over this plan.
- **Layout rules** (per shelf): 1 book → face-on real cover; all spines (incl. the
  leaning last book's horizontal room) fit the shelf width → all vertical; otherwise →
  left half vertical spines, right half horizontal pile. Books zone height = 9/16 × shelf
  width. Shelf preview capped (≈18 books); overflow reached via the shelf list.
- **Carousel** replaces the 2-up `LazyVGrid`: a horizontal `ScrollView` with
  `scrollTargetLayout` + `scrollTargetBehavior(.viewAligned)` for per-card snap. Card
  width ≈ 85% of the screen width with the next card peeking. Shelves sorted A→Z, then a
  trailing create card. The "Étagères" title, the carousel, then the "Tous les livres ·
  N" title and the flat list all live in the page's vertical scroll.
- **Gesture disambiguation on a shelf card**: a plain horizontal drag is left to the
  carousel scroll; a short long-press (~0.2s) *sequenced before* a drag arms the scrub
  (zoom + `.selection` haptic per book; release opens the book; sliding out of the shelf
  bounds cancels). A tap opens the shelf's list. `ShelfRowView` moves from a bare
  `DragGesture` to a `LongPressGesture(minimumDuration: 0.2).sequenced(before:
  DragGesture)`.
- **Shelf creation (write)** — first mutation in the shelf domain (ADR 0003 was
  read-only). `ShelfModel.createShelf(name:description:)` performs an **optimistic**
  `POST /api/shelves` via the existing `OptimisticMutating` pattern: insert a placeholder
  `Shelf` (optimistic id) locally, run the request in a model-owned background task,
  reconcile with the server's canonical shelf on success, revert on failure with the
  error surfaced through `AppErrorReporter`. Visibility defaults to private (`[]`).
- **Create UI** — `ShelfCreateCardView` renders an empty shelf (plank + wash) with a
  large + and a "Nouvelle étagère" label; tapping presents `ShelfFormView`, a sheet
  mirroring `ListFormView` (name field + optional description, submit via `AsyncButton`).
- **Server contract** (verified against inventaire/inventaire): create is
  `POST /api/shelves` with `{ name, visibility, description? }`; the shelf doc carries
  `_id, _rev, name, slug, description?, owner, visibility[], color, created, updated?`.
  Membership stays on the item; unchanged from ADR 0003.
- **No schema change** beyond ADR 0003 (Shelf model, Edition.dominantColorHex /
  numberOfPages, Shelf⇄InventoryItem relation already exist).

## Testing Decisions

- **Good tests here** exercise external behaviour through a module's public interface, not
  its internals: given inputs, assert the observable output. No SwiftUI rendering, no real
  network.
- **`ShelfBooksLayout`** (unit): feed synthetic book lists (varying counts and page
  counts) + widths and assert the returned plan and geometry — 0/1 book, an exactly-fits
  boundary, a clear overflow (correct `verticalCount` split), default-20 thickness when
  pages are absent, the 9/16 height cap, and pile fit-scaling. Pure and deterministic
  (the variance is seeded, not random), so no flakiness.
- **`ShelfModel.createShelf`** (behavioural, mocked network): with a stubbed
  `APIServicing`, assert the optimistic placeholder appears in the `ModelContext`
  immediately, is reconciled to the server's shelf id on success, and is reverted on
  failure. Prior art: the existing app-model tests drive models against a mock
  `APIService` and inspect the `ModelContext`; `ListModel.addEntitiesToList`'s optimistic
  flow is the closest analogue.
- Other modules (`syncShelves`/`linkItems`, loaders, all SwiftUI views) are **not** unit
  tested in this PRD.

## Out of Scope

- Renaming, deleting, or re-ordering shelves.
- Adding/removing a book to/from a shelf (drag-to-shelf, move, etc.).
- Friends'/other users' shelves in the carousel.
- Editing shelf colour or visibility from the app (visibility defaults to private).
- Animated/procedural changes to the watercolour beyond the existing static shader.
- Refining the scrub's index mapping for the mixed layout (currently a linear
  approximation over the full width) — tracked as a follow-up.
- Localising the new strings into `Localizable.xcstrings` (follow-up).

## Further Notes

- Builds on ADR 0003 (bookshelf inventory). This PRD expands scope from read-only to
  include shelf creation; the ADR should be amended or a short ADR 0004 added to record
  the write decision.
- The mixte layout (stories 8–13) is already implemented in `ShelfBooksView`; this PRD
  formalises it and calls for extracting `ShelfBooksLayout` so it can be tested.
- Known gesture fragility: `.sequenced` long-press-then-drag inside a horizontally
  snapping scroll view needs device testing; if arbitration is unreliable, fall back to a
  visible "scrub handle" or a mode toggle.
- The project's integration test suite hits the real inventaire.io server and is
  manual/CI-excluded; the new unit tests must stay network-free so they can run in CI.
