Title: Deleting a book from its own screen crashes the app
Labels: needs-triage, bug
Type: AFK

## Parent

Feature: docs/features/ — `ReCIT_iOS/Features/Book/BookDetailView.swift` and `ReCIT_iOS/AppModels/Inventory/InventoryModel.swift` are the sources.

## What to build

A crash, reported from a device on 2026-08-28 and not reproduced since: deleting an item from
the inventory, from the book screen's « Supprimer de mon inventaire », with no crash log kept.

So this issue is a reproduction first and a fix second. Do not fix by guessing.

## The reading that made it worth an issue

`BookDetailView.deleteOwnedItem()` awaits `InventoryModel.removeItem(_:modelContext:)`, which
deletes the `InventoryItem` from the store and saves — and then the book screen **stays on
screen**. Every part of it still holding that item is now holding a deleted SwiftData object:
the toolbar deciding what to offer, the ownership check, the transaction tag, and any parent
list rendering the same row. Reading a property of a deleted `@Model` after its context has
saved is a hard crash, not an optional-nil.

That is a hypothesis with a mechanism, not a diagnosis. It also explains "hard to reproduce":
it depends on what SwiftUI re-evaluates before the object is released, which changes with what
is on screen and how fast the server answered.

## Reproduce first

- Book screen, own item, delete, and stay put. Try it with the item also visible in the
  inventory list behind, and with a book that carries a transaction.
- Force it if the natural path will not: a deliberate re-read after the save reproduces the
  same access.
- Keep the log. Xcode's Organizer holds device crashes, and the stack tells an invalidated-object
  access apart from a concurrency fault — which is the other candidate worth ruling out.

## The likely fix, to be confirmed rather than assumed

The screen leaves when the thing it is about is deleted — the same reflex as
`issues/0064-deleting-a-list-leaves-you-on-its-corpse.md`. Popping before the delete lands, or
holding the id rather than the object, are both defensible; which one depends on what the log
says.

## Acceptance criteria

- [ ] The crash is reproduced, and the stack recorded in the fix's commit message
- [ ] Deleting a book from its own screen returns to where the user came from, with no crash
- [ ] Deleting the same book while the inventory list is behind it does not crash either
- [ ] The delete still fails loudly when the server refuses: a book that was not deleted must
      not vanish from the screen
- [ ] If the cause turns out not to be the deleted-object access described above, the real
      cause is written down here in its place

## Blocked by

None - can start immediately
