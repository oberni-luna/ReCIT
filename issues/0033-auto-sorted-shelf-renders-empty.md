Title: An auto-sorted étagère is created but renders empty
Labels: needs-triage, bug
Type: AFK

## Parent

Feature: docs/features/0008-ai-auto-sort.md

## What to build

A fix for this: run the auto-sort flow to the end, go back to the inventory tab, and the
étagère is there — named, labelled, tappable — with **nothing on its plank**. No error is
reported, and the flow ticked the étagère off as landed, which by design means both its
creation *and* its membership write succeeded.

Reported from a device on 2026-08-20 with an 8-book inventory and one proposed étagère
("Postmodern fiction").

## What has already been ruled out

- **Not a drawing bug.** `ShelfDrawnBooks.from(_:)` only sorts newest-first and caps at 20; it
  drops nothing. An empty plank means `shelf.items` is genuinely empty in the store.
- **Not the apply giving up early.** `AutoSortModel.apply(shelf:modelContext:)` throws
  `booksNoLongerInInventory` when it cannot resolve the plan's books, and that would have been
  reported and marked failed. The étagère was marked landed, so items *were* resolved and
  `addItemsAwaitingServer` returned without throwing.
- **Not a missing resync.** `RootView.refreshUserData` runs `syncShelves` on appear, whose
  second pass (`linkItems`) rebuilds membership from `by-ids&with-items=true`. The étagère is
  still empty after that, so **two independent server reads** produced an empty local
  membership.

## The two candidate causes

Both live in the reconcile, and both are silent by construction:

```
guard let dto = response.shelves[shelf._id] else { return }
shelf.items = localItems(ids: dto.items ?? [], modelContext: modelContext)
```

1. **The response is not keyed by the shelf's `_id`** (or omits the shelf entirely). The
   `guard` then returns and the relation is never written. On a freshly created étagère that
   leaves it empty for good, and nothing anywhere reports it — the write is indistinguishable
   from a successful one.
2. **The ids in `dto.items` do not match local `InventoryItem._id`** (shelf-item ids, uris,
   anything else). `localItems(ids:)` fetches on `_id`, so the resolution comes back empty and
   the relation is set to an empty array.

Note the same function treats missing data two different ways: a missing shelf key is "no
news" and returns, a missing `items` key is "empty membership" and writes. Only the second is
documented. Whatever the fix, those two should stop disagreeing.

**A hint on which is more likely, offered as inference rather than fact:** on the optimistic
single-book path, `apply` appends the item locally *before* the reconcile. Under cause 1 that
optimistic value survives and the bug is invisible — which fits "adding a book by hand has
always looked fine". Under cause 2 the reconcile would wipe it and the book would visibly
vanish from the shelf, which nobody has reported. Do not take that as settled; confirm from
the actual payload.

## How to tell them apart

`sendMembership` already sends with `debug: true`, so log the raw `add-items` response and the
`by-ids&with-items=true` response for the same étagère, and compare the keys against
`shelf._id` and the item ids against a local `InventoryItem._id`. One HTTP round trip settles
it. Check the live OpenAPI spec rather than the archived GitHub mirror for the contract.

## Acceptance criteria

- [ ] The raw shapes of both responses are recorded in the fix's commit message or in the
      feature doc — the next person must not have to re-derive them
- [ ] Running the auto-sort flow leaves each created étagère holding the books the plan showed,
      visible on the plank without relaunching the app
- [ ] A membership reconcile that cannot find its shelf in the response no longer passes
      silently: it either reports or is explained in a comment as genuinely safe, and the two
      missing-data cases in `sendMembership` are consistent with each other
- [ ] Adding a single book by hand still puts it on the shelf, and it survives the next
      `syncShelves` — the optimistic path and the bulk path share this code, so a fix for one
      must not break the other
- [ ] A test covers the reconcile at the seam that can be tested without the network: given a
      response payload, the expected local membership. Prior art: `ShelfModelTests`
- [ ] `docs/features/0008-ai-auto-sort.md` gains a line under its known gaps or notable
      decisions recording what the real contract turned out to be

## Blocked by

None - can start immediately
