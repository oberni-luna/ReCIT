# ADR 0001 — SwiftData-reactive UI, background sync, optimistic writes

- Status: Accepted
- Date: 2026-08-03

## Context

RECITs is a local-first cache over the `inventaire.io` backend. Two recurring bugs
motivated a standard:

1. Detail screens (works/authors/editions, transactions) showed stale or empty data
   because a first sparse fetch was cached forever, or because a "sync" **deleted and
   re-inserted** the very `@Model` object a screen was displaying — destroying object
   identity and breaking SwiftUI observation.
2. User actions (post a message, change a transaction state) only appeared after a
   manual refresh, because the mutation hit the server and never touched SwiftData.

We want one architecture for the whole app.

## Decision

Three invariants, one direction of data flow:

```
View ──(@Query / passed @Model)──► reads SwiftData ONLY
  │ calls behavior
  ▼
*Model (@MainActor @Observable)    behavior only; returns Void / throws
  │  ├─ sync…()        Server → App: UPSERT-in-place
  │  └─ …Optimistic()  App → Server: local-first, background WS
  ▼
APIService                         DTO in / out
```

### Invariant 1 — UI is bound to SwiftData and reactive

Views render from `@Query` (preferred) or a passed `@Model`. They never read a model
method's return value for display. `*Model` methods return `Void`/`throws`; the store is
the single source of truth the UI observes.

### Invariant 2 — Server → App is always UPSERT-in-place

Every sync updates existing objects **by `_id`** and inserts only the genuinely new
ones; it never deletes-then-reinserts. Preserving object identity is what keeps an
already-rendered view reactive across a background sync. Use
`ModelContext.upsert(...)` (`AppModels/Common/RemoteUpsert.swift`) for sync-mapped
models, or a bespoke upsert when relationship resolution is async (e.g. transactions).

Each `@Model` provides:
- `convenience init(dto:)` — build a new instance.
- `update(from dto:)` — idempotent, non-nil-guarded merge into an existing instance.
  Sparse server payloads must not wipe good local data.

### Invariant 3 — App → Server is optimistic, through one runner

User-initiated writes go through `OptimisticMutating.optimistic(_:apply:revert:request:reconcile:)`
(`AppModels/Common/OptimisticMutating.swift`):

1. `apply` mutates SwiftData and saves immediately → the UI reacts at once.
2. `request` runs in a background `Task` owned by the app-scoped model (survives sheet /
   view dismissal).
3. On success, `reconcile` aligns the local store with server truth (e.g. swap an
   optimistic placeholder for the server object, keyed by `_id`).
4. On failure, `revert` undoes the local change and the error is surfaced through the
   shared `AppErrorReporter`, observed once near the root and shown as a SnackBar.

Placeholders created before the server confirms use the `optimistic:` id prefix so
reconcile/revert can find them.

Not every write is optimistic: only user-initiated writes where instant feedback matters.
Pure background syncs just upsert.

**Creates and deletes stay server-first (intentional exception).** Optimistic *delete*
revert is unreliable under SwiftData — a deleted object is invalidated and re-inserting a
faithful copy (with relationships) is fragile. Optimistic *create* would need a temp-id →
server-id reconcile. Both `removeItem` / `deleteElementsInList` / `postNewItem` also
immediately precede a screen dismiss, so the single round-trip's latency is invisible.
Optimism is therefore applied to in-place field updates and additive list writes, where
revert is a clean inverse.

## Consequences

- New shared types under `AppModels/Common/`: `SyncFailure`, `AppErrorReporter`,
  `OptimisticMutating`, `ModelContext.upsert`.
- Reference implementation: `TransactionModel` (message + state changes) and the
  entity refresh in `EntityModel`.
- `@Attribute(.unique)` means upsert must fetch-existing-then-update; a blind insert of a
  duplicate `_id` traps.
- Heavy syncs stay on `@MainActor`; move to a background `ModelActor` only if measured to
  jank — do not pre-optimize.
- Tests: mock `APIService`, in-memory store with a unique per-container URL, suites
  `.serialized`.

## Migration (incremental, as features are touched)

- P1 (done): removed delete+reinsert from `ListModel.syncLists`; added `update(from:)` to
  `EntityList`. `syncTransactions` / `syncInventory` already upsert in place.
- P2 (done): `InventoryModel.updateItem{Transaction,Details}Optimistic` and
  `ListModel.addEntitiesToList` now go through the runner. Creates/deletes stay
  server-first (see exception above).
- P3 (done): `TransactionDetailView` sources its transaction from `@Query`-by-id;
  `InventoryItem.update(from:)` added and used by `syncInventory`.
  `InventoryItemDetailView` stays on its `@Bindable` passed object (needs the two-way
  picker binding; its sync now upserts, so identity is stable).
- Remaining: audit any other sync for delete+reinsert; add `init(dto:)`/`update(from:)`
  to the last models lacking them as they're touched.
