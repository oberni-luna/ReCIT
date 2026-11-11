---
issue: 125
status: todo
wiki: [[architecture]], [[performance]], [[shelves]], [[network]]
note: Second of the 2026-11-10 perf pass. Baseline from #124. Split on 2026-11-11 — the other sync domains are #135.
created: 2026-11-11
---

## Context / Decisions

> decode and upsert without blocking the UI
>
> Finding from the 2026-11-10 perf pass: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so `APIService` decodes every JSON on the main thread; `UserDataSync` and `InventoryModel.syncInventory` upsert into the main `ModelContext`, no `@ModelActor` anywhere; `syncInventory` saves once per author; 17 `print()` in AppModels and Features.

The baseline of #124 (`docs/wiki/performance.md`) puts the lag on the first sync: while friends' inventories sync, scrolling hitches at 241 ms/s on every screen, and a friend's first inventory costs about 180 ms per item. ADR 0001 kept heavy syncs on `@MainActor` « only if measured to jank »: it is now measured.

- **Scope of #125: inventories and the entities they pull.** `syncInventory` (mine and each friend's) and the work/author fetches it makes leave the main actor, with everything they need. The other domains — my user, étagères, relations, groups, lists, transactions, network lists — are #135, on the base laid here.
- **One `@ModelActor` per domain.** `actor InventorySync` in `AppModels/Inventory/`, `actor EntitySync` in `AppModels/Entity/`, each on a background `ModelContext` of the shared container. They hold the sync logic moved out of `InventoryModel` / `EntityModel`. The `*Model`s keep their observed state and their optimistic writes on the main actor. `UserDataSync` still orchestrates the order.
- **Nothing `@Model` crosses an actor.** Users and items go in as ids (`_id` or `PersistentIdentifier`); each actor fetches its own.
- **Decoding off the main actor.** `APIService` becomes `nonisolated` and `Sendable`; the DTOs it decodes for these syncs become `nonisolated`. `AbsoluteImageURL` and whatever the upserts call follow.
- **Saves at most once a second.** The background context saves when a second has passed since its last save, and once at the end. Books still arrive as they come; each save is one refetch of the `@Query`s on screen, not one per author.
- **First-sync progress (feature 0027) moves with the saves.** `InventorySync` reports the progress to `InventoryModel` on the main actor at each save. `firstSyncProgress` and the bars stay where they are.
- **Optimistic writes protected by a shared registry.** A `Sendable` registry (`Mutex`) of the objects with a write in flight, by id. `OptimisticMutating` fills it and empties it; the sync actors skip those objects. It replaces `ShelfModel.isMembershipWriteInFlight`.
- **ADR 0001 upsert-in-place still holds.** Upserts by `_id` in the background context; identity survives, open screens stay live through the save.
- **A new ADR** records the move off the main actor and amends 0001's « Heavy syncs stay on `@MainActor` ».
- **Logs.** The `print`s of the sync go to a `Logger`; `debug: true` leaves the sync path (`EntityModel.swift:246`). The `debug` log of whole response bodies under `asso.recits` is the likeliest reason the sync signposts went missing in #124's traces.
- **Measured.** Scenario 1 of `docs/wiki/performance.md`, before and after, one row in its Before / after table. Commit as `perf:`.
- **Blocked by #124**, whose signposts and baseline this measures against.

## Acceptance criteria

- On an iPhone, Release, scenario 1 (empty store) of `docs/wiki/performance.md`: scroll hitches during the first sync ≤ 30 ms/s (baseline 241 ms/s).
- Same trace: no hang over 250 ms.
- Same trace: every `asso.recits` sync interval is there — the nine phases and one « Inventory sync » per user — so the phase rows of the baseline can be filled.
- A friend's books show up in their profile and in « Chez mes amis » while their first sync runs, not all at the end; the progress bar of feature 0027 still moves.
- A shelf change or a comment made during a sync is not undone by it: after the sync, the screen shows what the reader did.
- `syncInventory`'s work, author and item fetches, decoding and upserts run off the main thread; the main `ModelContext` is not written by the inventory sync.
- Existing tests green; `InventoryModel` / `UserDataSync` sync tests cover the actor path.
- `docs/wiki/performance.md` Before / after has the #125 row filled; the new ADR is linked from `docs/wiki/architecture.md`.

## Implementation

## Review

## Verification

## Feedback
