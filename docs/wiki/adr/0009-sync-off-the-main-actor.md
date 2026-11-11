# ADR 0009 — Syncs off the main actor

- Status: Accepted
- Date: 2026-11-11
- Amends: [ADR 0001](0001-swiftdata-reactive-optimistic.md), whose consequences kept heavy syncs
  on `@MainActor` « only if measured to jank ». It is now measured.

## Context

The baseline of #124 ([performance](../performance.md)) puts the lag on the first sync: while
friends' inventories sync, scrolling hitches at **241 ms/s** on every screen — twenty-four times
Apple's critical line — and a friend's first inventory costs about 180 ms per item.

Everything that sync did ran on the main thread. The target defaults to the main actor
(`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), so `APIService` decoded every answer there;
`InventoryModel.syncInventory` upserted into the main `ModelContext`, and saved it once per
author, each save a refetch of every `@Query` on screen.

## Decision

1. **One model actor per sync domain**, on a background context of the shared container. #125
   moves the inventories and the entities they pull: `InventorySync` (`AppModels/Inventory/`)
   and `EntitySync` (`AppModels/Entity/`). The `*Model`s keep their observed state and the
   reader's optimistic writes on the main actor. `InventoryModel.syncInventory(forUser:modelContext:)`
   stays, as the main-actor front of the actor: the early return, the « Inventory sync »
   signpost, the first-sync progress. `UserDataSync` still decides the order.
2. **Nothing `@Model` crosses an actor.** A user goes in as its `_id`, and the actor fetches its
   own copy from the store — so a user must be saved before its inventory is synced.
3. **Decoding off the main actor.** `APIServicing` and `APIService` are `nonisolated` and
   `Sendable`, and so are what these syncs decode and call: their DTOs, the `Entity` protocol
   (which makes `Author`, `Work` and `Edition` nonisolated), the `ModelContext` upserts,
   `InventorySyncProgress`.
4. **At most one save a second**, and one at the end. Books still arrive as they come; each save
   is one refetch of what is on screen, not one per author. The first-sync progress of feature
   0027 is reported at each save.
5. **Writes in flight are left alone.** `InFlightWrites` is a `Sendable` registry, behind a
   `Mutex`, of the models a write of the reader's is still sending, counted so that two
   overlapping writes do not free each other's. `OptimisticMutating` enters its subjects for the
   whole cycle, the étagère membership writes their étagère and books. The inventory sync skips
   those items; the étagère sync skips its membership pass when one of its étagères is held. It
   replaces `ShelfModel.isMembershipWriteInFlight`, an app-wide flag that a friend's sync waited
   on too.
6. **ADR 0001's upsert in place still holds**, in the background context: an item is updated by
   its `_id`, never deleted and inserted again, so identity survives the save.

## How the actor stays off the main thread

Found while building it, in tests on the iOS 27.2 simulator.

- **A model actor runs each job on the thread that hands it over.** `DefaultSerialModelExecutor`
  does not have a thread of its own: an actor method called from the main actor runs on the main
  thread, and so does whatever follows an `await` of the main actor — wherever the actor was
  created. So `InventorySync.sync` is a `@concurrent nonisolated` entry point that calls into the
  actor from the global executor, and the actor never awaits the main actor: the progress leaves
  through an `AsyncStream`, read by `InventoryModel` on the main actor.
- **`EntitySync` shares the sync's executor and context.** `InventorySync` makes it with its own
  `modelExecutor`: the works it upserts are there for the items to be linked to, and are saved
  with the sync's saves, never on their own.
- **`@Query` sees a background save at once; a model the main context already holds does not.**
  A fetch refreshes it. So `syncInventory` fetches the synced user again once the actor is done,
  for its first-sync state; screens bound through `@Query` stay live. A model held outside any
  `@Query` catches up on its next fetch.

## Consequences

- The main context is not written by the inventory sync.
- My user, étagères, relations, groups, lists, transactions and network lists still sync on the
  main actor. #135 moves them, the same way.
- `APIService` now decodes every answer off the main actor, but the DTOs of those other domains
  are still main-actor: each call that decodes one draws an `IsolatedConformances` warning in
  Swift 5 mode, an error in Swift 6. #135 makes them `nonisolated` with their domain.
- A write that starts between an item's merge and the next save — a second at most — can still
  lose to that save. `InFlightWrites` protects an item from the moment its write starts, not
  before.
- `EntityModel.fetchEntities` and `getOrFetchAuthors` keep their own copy of what `EntitySync`
  does for the screens: `EntityModel`'s length is pinned by the SwiftLint baseline.
- In tests, `MockAPIService` stays on the main actor, so the actor resumes there after each stub:
  the tests prove what the sync writes and skips, not which thread it runs on.
- The hitch rate after the move is owed: scenario 1 of [performance](../performance.md), on an
  iPhone.
