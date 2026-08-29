Title: Genre enrichment writes to a `Work` whose row can have gone, and the app aborts
Labels: needs-triage, bug
Type: AFK

## Parent

Feature: `ReCIT_iOS/AppModels/Genre/GenreEnrichmentModel.swift`, called from
`ReCIT_iOS/Features/Book/BookDetailView.swift` (`enrichGenres(for:)`).
Found on 2026-08-29 by `scripts/e2e.sh` — see docs/features/0012-end-to-end-scenario.md.

## What happened

A crash on the book screen, captured on the simulator, **distinct from the one that was
issue 0065** — different stack, different mechanism, same screen. 0065 was a *read* of a deleted
model and is fixed (`PersistentModel.isStillInTheStore`); this one is a *write*.

Simulator: iPhone 17, iOS 27.0, Debug. `EXC_CRASH (SIGABRT)`: an Objective-C exception raised
inside CoreData and rethrown through SwiftData, which no Swift `catch` can take.

Crashing thread:

```
CoreData    developerSubmittedBlockToNSManagedObjectContextPerform
CoreData    -[NSManagedObjectContext performBlockAndWait:]
SwiftData   ?
ReCIT_iOS   GenreEnrichmentModel.enrich(batch:modelContext:)
ReCIT_iOS   GenreEnrichmentModel.enrichWorkIfNeeded(_:modelContext:)
ReCIT_iOS   BookDetailView.enrichGenres(for:)
ReCIT_iOS   closure #4 in closure #1 in BookDetailView.body.getter
```

The exception itself:

```
objc_exception_throw
_PFFaultHandlerLookupRow
_PF_FulfillDeferredFault
_PF_ManagedObject_WillChangeValueForKeyIndex
_sharedIMPL_setvfk_core
…
KeyedEncodingContainer.encode(_:forKey:)
```

Read bottom-up: something sets an encoded property (an array or a date — `Work.genres`,
`genresEnrichedAt`, `genresRevision` are the candidates), CoreData has to fault the object in to
do the bookkeeping, the row is not there, and it throws.

## Where it comes from

`enrich(batch:modelContext:)` captures `[Work]` references, then `await`s **two** network round
trips — `entityModel.fetchEntities`, then `resolveGenreLabels` — and only afterwards writes:

```swift
for (workUri, genreUris) in genreUrisByWork {
    guard let work = worksByUri[workUri] else { continue }
    work.applyEnrichedGenres(labels(for: genreUris))
}
```

Those references are seconds old by then, and the works came out of a relationship
(`edition.works` in `BookDetailView`), so they are faults rather than materialised objects. The
window is wide, the screen it runs from is one the user deletes things from, and a background
sync (`RootView.refreshUserData`) runs over the same store throughout.

**What is not established: what actually removes the row.** Nothing in the app deletes a `Work`
— `grep 'modelContext.delete'` finds items, lists, list elements, shelves, transactions and the
user, never a work. So either a sync path replaces works rather than upserting them in place
(which ADR 0001's second invariant forbids, and whose migration is explicitly incremental), or
the fault belongs to something else in the graph. **That is the thing to find out**, and it
should be found out before the fix below is chosen, because it may be the real bug.

## Candidate fix, written but withdrawn

Deliberately not shipped, and reverted on 2026-08-29: it makes the crash go away without
anyone understanding why the row disappears, which is how a symptom gets buried.

```swift
// Look the work up again instead of writing through a reference captured two round trips ago.
for (workUri, genreUris) in genreUrisByWork {
    guard let work = entityModel.localWork(modelContext: modelContext, uri: workUri) else { continue }
    work.applyEnrichedGenres(labels(for: genreUris))
}
```

It is cheap (one fetch per work), it loses nothing (nothing is stamped, so the next screen that
opens the work asks again), and it is correct under every hypothesis above. It is also a plaster
if a sync really is deleting and reinserting works, because everything else holding one has the
same problem.

## Reproduce

`scripts/e2e.sh`. It surfaced on the « Suppression des livres de l'inventaire » step, roughly
two minutes in, after several books had already been deleted and reopened — so it needs the
book screen opened repeatedly while a sync is running, not a single delete.

## Acceptance criteria

- [ ] What removes the `Work`'s row is identified and written down here
- [ ] Enriching genres from the book screen no longer aborts, with a stack or a reproduction to
      show the before
- [ ] If a sync path is replacing works rather than upserting them, that is fixed at the sync —
      ADR 0001, invariant 2 — and not only guarded at this call site
- [ ] `scripts/e2e.sh` runs its deletion step to the end twice in a row

## Blocked by

None - can start immediately
