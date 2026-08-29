Title: Deleting a book from its own screen crashes the app
Labels: needs-triage, bug
Type: AFK

## Parent

Feature: docs/features/ — `ReCIT_iOS/Features/Book/BookDetailView.swift` and `ReCIT_iOS/AppModels/Inventory/InventoryModel.swift` are the sources.

## What to build

A crash, reported from a device on 2026-08-28 and not reproduced since: deleting an item from
the inventory, from the book screen's « Supprimer de mon inventaire », with no crash log kept.

So this issue is a reproduction first and a fix second. Do not fix by guessing.

## Investigated 2026-08-28 — the hypothesis below is REFUTED, and the issue stays open

Two things were established before writing any fix, and both contradict what this issue
originally assumed.

**The deleted-object access does not trap.** A throwaway probe against a real container deleted
an `InventoryItem` and read it back every way the book screen does — through
`edition.items`, directly, through a to-many (`shelves`) and a to-one (`edition`) — in both
windows, before `save()` and after:

```
avant suppression : items = 1
supprimé, avant save : items = 1 · ownerId via relation = me · shelves = 0
après save : items = 0
lecture directe sur l'objet supprimé : ownerId = me · isDeleted = false
relations sur l'objet supprimé : shelves = 0 · edition = "Probe"
```

Nothing traps, the relationship updates itself, and the deleted object keeps answering. So
"the screen holds a deleted model" is **not** the mechanism, at least not on the main context
without concurrency.

**Staying on the screen is deliberate and correct.** `deleteOwnedItem` carries a comment saying
so: the book screen is about the *edition*, which still exists — only the "my copy" section goes
away, and the add-to-inventory action comes back. Unlike a deleted list, whose screen loses its
whole subject, this screen loses one section. **The claim below that this is the same shape as
`0064` is wrong**, and no dismiss should be added here to "fix" the crash.

What is left to look at, none of it verified:

- concurrency around the `await` in `removeItem` — the only part not covered by the probe;
- `BookShelfMenu(item:)`, which hands the item to a UIKit menu that may outlive it;
- `borrowableItems(_:)` and `item.owner`, read from the same toolbar;
- something else entirely, which is why the log matters more than any of this.

**Do not ship a fix without a log or a reproduction.** One was captured on 2026-08-29 — see the
next section, which answers this one.

## Reproduced 2026-08-29, with a stack — it is `InventoryCell`, not `BookDetailView`

The end-to-end scenario (`docs/features/0012-end-to-end-scenario.md`) reproduced it on the
simulator, on its first full run, and left a crash report. **The mechanism is the deleted-object
access after all — but in the wrong view.** The 2026-08-28 probe cleared every read
`BookDetailView` makes; nobody looked at the list *behind* it.

Simulator: iPhone 17, iOS 27.0, Debug. `EXC_BREAKPOINT (SIGTRAP)` on the main thread, which is
a Swift runtime trap, not a nil dereference:

```
libswiftCore   _assertionFailure(_:_:file:line:flags:)
SwiftData      ?
SwiftData      ?
SwiftData      ?
ReCIT_iOS      InventoryItem.transaction.getter
ReCIT_iOS      closure #2 in closure #1 in closure #1 in InventoryCell.body.getter
SwiftUICore    HStack.init(alignment:spacing:content:)
ReCIT_iOS      closure #1 in closure #1 in InventoryCell.body.getter
…
ReCIT_iOS      InventoryCell.body.getter
SwiftUICore    ViewBodyAccessor.updateBody(of:changed:)
```

So: `BookDetailView` deletes the item and stays, as designed; the inventory list underneath it
re-renders with that item still in its `ForEach`, `InventoryCell.body` reads
`item.transaction`, and SwiftData traps on a property of a deleted model.

That is exactly the third acceptance criterion below — "deleting the same book while the
inventory list is behind it does not crash either" — and it is why the crash was "hard to
reproduce": it needs the list to be *behind* the book screen, which is the case when the book
was opened from « Tous les livres » and not from a search.

**What the fix has to survive**, beyond making the trap go away: the scenario opens a book from
the inventory list, deletes it, walks back, and expects the row to be gone and the count in
« Tous les livres · N » to drop. A guard that leaves a ghost row would pass a crash test and
fail that one.

## The reading that made it worth an issue *(kept for the record — refuted above)*

`BookDetailView.deleteOwnedItem()` awaits `InventoryModel.removeItem(_:modelContext:)`, which
deletes the `InventoryItem` from the store and saves — and then the book screen **stays on
screen**. Every part of it still holding that item is now holding a deleted SwiftData object:
the toolbar deciding what to offer, the ownership check, the transaction tag, and any parent
list rendering the same row. Reading a property of a deleted `@Model` after its context has
saved is a hard crash, not an optional-nil.

That is a hypothesis with a mechanism, not a diagnosis. It also explains "hard to reproduce":
it depends on what SwiftUI re-evaluates before the object is released, which changes with what
is on screen and how fast the server answered.

## Reproduce first *(done — `scripts/e2e.sh`, step « Suppression des livres de l'inventaire »)*

The list has to be **behind** the book screen, which is what the earlier attempts were missing:
open the book from « Tous les livres », delete it, stay put.

## The fix is not known yet

The first candidate — leave the screen, as `issues/0064-deleting-a-list-leaves-you-on-its-corpse.md`
does — is **wrong here**, and the investigation above says why: this screen is about the edition,
not the copy, and staying is a deliberate decision written into `deleteOwnedItem`. Adding a
dismiss would trade the crash for a behaviour change nobody asked for — and it would not even
work, since the trap is in the list behind, not on this screen.

## Acceptance criteria

- [x] The crash is reproduced, and the stack recorded — see above (2026-08-29). Reproduce it at
      will with `scripts/e2e.sh`, whose « Suppression des livres de l'inventaire » step is the
      path that triggers it.
- [ ] Deleting a book from its own screen no longer crashes, with the screen still staying put —
      the 'my copy' section drops and the add-to-inventory action returns, as designed
- [ ] Deleting the same book while the inventory list is behind it does not crash either
- [ ] The delete still fails loudly when the server refuses: a book that was not deleted must
      not vanish from the screen
- [ ] If the cause turns out not to be the deleted-object access described above, the real
      cause is written down here in its place

## Blocked by

None - can start immediately
