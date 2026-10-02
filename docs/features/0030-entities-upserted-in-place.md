# Works, authors and editions upserted in place

Shipped on 2026-10-02, from PRD 0016 and issues 0099–0101, in an autopilot run that followed an
architecture audit. Nothing changes on screen. What changes is what a sync leaves behind in the
store.

## What it does

- **A sync no longer empties what the app stored on a work or an edition.** A work's genres, the
  marker that says they were asked, and the edition a search opens for it all survive a sync now.
  So do an edition's works, its cover colour and its page count. Before, every inventory sync wiped
  them, and they were asked for or computed again.
- **A work under several authors keeps all of them**, however many times the inventory names it.
- **Genre enrichment no longer writes to a work that has gone.** It looks each work up again once
  its two requests have answered, and skips one that was deleted in the meantime. That is the crash
  of issue 0067.
- **An optimistic write no longer reverts or reconciles a model whose row has gone**, for example a
  book deleted while its notes were being saved. The failure is still reported.
- **A work's publication date is its publication date** (`wdt:P577`). It used to be read from
  `wdt:P570`, the date of death, which a work never carries.
- **A list's creation date is in the right millennium.** It is now converted from milliseconds.

## What was removing the row (issue 0067)

`uri` is `@Attribute(.unique)` on `Work`, `Author` and `Edition`. Several paths built a fresh
entity for a uri the store already held, and inserted it:

- `InventoryModel.syncInventory`, for every work on every sync, once per author;
- `InventoryItem.init(itemDTO:)`, for every new item's edition;
- `EntityModel.getOrFetch*`, for a uri the server answered with a redirect.

`UniqueCollisionTests` pins down what SwiftData does with that second insert. It keeps one row, the
held one, and pours the newcomer's values into it, which is how the local fields came back empty.
The newcomer stays registered with a permanent id and no row behind it:

- `isStillInTheStore` answers `true` for it;
- writes made through it are lost;
- once it is a fault again, a write raises `_PFFaultHandlerLookupRow` from inside CoreData. That is
  the stack in issue 0067.

## Technical surface

- **`ModelContext+Entities`** (`AppModels/Entity/`) is the one way an entity enters the store:
  - `upsertAuthors(_:apiService:)`, `upsertWork(_:authors:apiService:)`,
    `upsertEdition(_:works:apiService:)`, and `edition(uri:snapshot:apiService:)` for an item;
  - it looks the uri up by predicate, merges fields through the models' own `update(entityDTO:)`
    (which never lets a sparse payload wipe a field), and inserts only what is missing.
- **`Work.mergeAuthors(_:)` and `Edition.mergeWorks(_:)`** merge a relationship by union on the uri:
  calling twice adds nothing.
- **`InventoryItem.init(itemDTO:forUser:edition:)`** is handed its edition and no longer builds
  one.
- **`EntityModel`** (`refresh*`, `getOrFetch*`, `getAuthorWorks`, `getWorkEditions`) and
  **`InventoryModel`** (`syncInventory`, `postNewItem`) go through the extension above. Nothing
  outside it builds an author, a work or an edition and then inserts it.
- **`GenreEnrichmentModel.enrich(workUris:)`** carries uris across its awaits, and re-reads each
  work through `EntityModel.localWork` plus `isStillInTheStore` before writing.
- **`optimistic(_:subjects:apply:revert:request:reconcile:)`** checks, once the request has
  answered, whether every subject is still in the store. If one is not, it skips `revert` and
  `reconcile`.
  - These writes declare their subjects: an item's transaction and notes, a shelf's edit and its
    membership writes (shelf and item), adding to a list, a transaction's message and state, a
    user's relation.
  - The shelf creation and deletion writes declare none: their closures only touch placeholders or
    snapshots of their own.
- **`MockAPIService.onFetch`** is a hook a test uses to change the store while a model waits on the
  network.
- Tests:
  - `UniqueCollisionTests`, `EntityUpsertTests` (the upsert, and `syncInventory` played twice);
  - `GenreEnrichmentModelTests` — the first tests that model has had;
  - `OptimisticRunnerTests`;
  - two mapping tests in `ModelMappingTests`.

## Notable decisions

- **An extension on `ModelContext`, not methods on `EntityModel`.** `InventoryModel` only gets its
  `EntityModel` once `start()` has run. A sync must not be able to go back to building entities by
  hand because that dependency is not there yet.
- **Relationships merge by union, never by replacement.** One consequence: an author the server
  stops listing on a work stays attached locally. That is rare, and much cheaper than the opposite
  error, a work that loses one of its authors every time it is synced under the other.
- **An item's edition, when the store already holds it, is left as it is.** The snapshot is a few of
  the entity's fields copied onto the item; the entity, fetched by `EntityModel`, is the better
  source.
- **The runner takes the models it would write to, rather than ids to re-read.** It is the smallest
  change that covers every call site without rewriting their closures. A subject that has gone
  means there is nothing to put back and nothing to align.
- **Issue 0067 is updated, not closed.** Its e2e criteria are still owed.

## Not done, not verified

- Build green; the unit suite is green, 741 tests.
- **`scripts/e2e.sh` not played**, so issue 0067's last two criteria are still open. The deletion
  step should run to the end twice in a row.
- Not established: which path handed `GenreEnrichmentModel` a row-less twin rather than the
  surviving row. The re-read makes the enrichment independent of the answer.
- An install that synced before this change may still hold works whose genres were wiped. The next
  book screen or arrangement run asks for them again, since their `genresEnrichedAt` is `nil`.
- Out of scope, from the same audit:
  - `EntityModel.refresh*` still return values that views display (ADR 0001, invariant 1);
  - uris are still bare strings.
