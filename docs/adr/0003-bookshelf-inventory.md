# ADR 0003 — Bookshelf (étagère) inventory screen

- Status: Accepted
- Date: 2026-08-05

## Context

The inventory tab (`MyInventoryView`) is a flat, conventional `List` of `InventoryCell`
rows. We want a distinctive, book-centric home for the collection: physical **shelves**
(étagères) with painted watercolor spines, matching a set of hand-painted mock designs
(a light watercolor wash behind, a wooden plank on top, painted book spines tinted by each
cover's colour).

inventaire.io already models **shelves** server-side, but this client never integrated them:

- There is **no `Shelf` model, no shelf sync, no shelf→item link** in the app.
- `EntityList` is inventaire *lists* (curated sets of work/author **URIs**), **not** shelves —
  different endpoint, different semantics. It is not reusable as a shelf carrier.
- The fetched `ItemDTO` (`/api/items/by-ids`) **drops** the server's shelf membership: it
  decodes no `shelves` field, though `NewItemDTO` has a write-only `shelves: [String]` (always
  sent `[]`).
- No dominant-colour extraction from cover images exists anywhere.

### Server facts (verified against inventaire/inventaire `server/`)

- **Shelf doc**: `_id`, `_rev`, `name`, `slug`, `description?`, `owner`, `visibility[]`,
  **`color` (hex)**, `created`, `updated?`.
- **Membership lives on the item**: `Item.shelves: ShelfId[]` (`server/types/item.ts`). A shelf
  is metadata only; "what's on it" is derived by filtering items.
- **Endpoint**: `GET /api/shelves?action=by-owners&owners=<userId>`.
- **Response is a dict keyed by id**: `{ shelves: { "<id>": Shelf } }` (server uses `keyBy`),
  *not* an array. Private shelves' `visibility` is stripped for other users.

## Decision

Ship a **read-only** bookshelf screen backed by a **real** shelf domain. Scope, resolved via
a design interview:

### Data

1. **New `@Model Shelf`** — `_id` (unique), `_rev`, `name`, `slug`, `description`, `ownerId`,
   `visibility: [String]`, `colorHex`, `created`, `updated`. Follows ADR 0001 `init(dto:)` +
   idempotent `update(from:)`, upserted via `ModelContext.upsert`.
2. **Many-to-many `Shelf` ⇄ `InventoryItem`** (`shelf.items` / `item.shelves`). A book on N
   shelves appears N times — intentional, accepted. **"Sans étagère"** = items whose relation
   is empty.
   - The relation is **built at sync** from each item's server `shelves: [ShelfId]` array
     (decoded onto `ItemDTO`), by resolving ids → local `Shelf`. This forces a **sync order:
     shelves before items**.
3. **`Edition.dominantColorHex: String?`** — the painted spine colour, extracted lazily from
   the cover (below). Shared across items of the same edition.
4. Additive SwiftData migration (new model + properties + relation) — lightweight, automatic.

### Sync

- **New `ShelfModel.syncShelves(forUser:modelContext:)`** → `GET /api/shelves?action=by-owners`
  for **my** shelves only (friends' shelves out of scope). Decodes the id-keyed dict, upserts
  its values.
- Wired in `RootView+RefreshUserData` **before** `syncInventory`, so `Shelf` objects exist when
  items resolve their relation. Injected like the other app models (`@State` in `RootView`,
  `.environment`, registered in the `ReCIT.swift` `ModelContainer` schema).
- Known limitation: inventory sync is gated on `User.lastItemAdded`; a pure shelf-membership
  change server-side won't re-trigger item linking. Acceptable for v1 (read-only, rare).

### Screen (replaces `MyInventoryView` as the inventory tab root)

- `LazyVGrid`, **2 shelves per row**, each half the width minus margins, **all equal width**,
  sorted **A→Z** by name.
- Per shelf, books ordered by **`item.created` desc** (most-recently-added first):
  - **0–5 books** → vertical painted spines.
  - **6+ books** → a horizontal painted **pile** (preview of the first 10). Overflow beyond the
    preview is reached by drill-in.
- Below the shelves: a standard **"sans étagère"** list (reuses `InventoryCell`).
- **Search**: active → hide shelves, show the flat filtered list (reuses `InventoryListContent`);
  empty → shelves. One tab, two modes.
- Assets: the watercolour wash and the wooden plank are bundled PNGs.

### Rendering

- **Metal shader** for the procedural watercolour spines (`.colorEffect`/`Shader`), tint =
  `Edition.dominantColorHex` uniform, per-book seed for variation, **rendered statically** (no
  per-frame animation → no battery cost). Wash + plank stay as image assets.

### Colour extraction

- **Lazy, per visible spine**: on appear, fetch a small cover, compute a normalised dominant
  colour (average + saturation/lightness normalisation), persist `Edition.dominantColorHex`,
  fade the spine in. Parchment placeholder meanwhile. Never recomputed.

### Interaction (no hover on iOS)

> **Superseded by ADR 0005.** The scrub described below shipped (via a UIKit
> recognizer, PRD 0002) and was then replaced by tap-to-select; a body tap no longer
> opens the shelf list. Kept here as the original decision.

- **Tap** anywhere on a shelf → `ShelfDetailView` (a standard `InventoryCell` list of the
  shelf's books). Tapping a spine does **not** open that book — it opens the shelf list.
- **Tap + horizontal swipe** across the books → scrub: X maps to a book, each zooms + a haptic
  tick as the finger crosses it; release on a book → push its `BookDetailView`; release off a
  book → cancel. Disambiguated by `DragGesture(minimumDistance ~10)`.
- New `NavigationDestination.shelf(id:)`.

## Out of scope (v1)

Create/rename/delete shelves, add/remove a book to a shelf, friends' shelves, animated
watercolour. No write endpoints, no optimistic mutations.

## Consequences

- First shelf domain in the app; `EntityList` stays list-of-URIs, unrelated.
- The book-on-many-shelves duplication is by design; any "count of my books" must dedupe on
  `InventoryItem._id`.
- Colour quality depends on the extraction heuristic; a plain average can be muddy and may need
  calibration against real covers.
- The exact `Shelf` DTO field nullability (e.g. `color`, `description`) is decoded defensively
  (optionals) since private-attribute filtering can omit fields.
