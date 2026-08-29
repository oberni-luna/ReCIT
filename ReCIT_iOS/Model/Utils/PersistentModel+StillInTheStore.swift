//
//  PersistentModel+StillInTheStore.swift
//  ReCIT_iOS
//
//  Whether a `@Model` a view was handed still has a row behind it.
//
//  **Reading a persisted property of a deleted model is a trap, not a nil.** SwiftData raises
//  from inside the property getter — the app is gone, with an `EXC_BREAKPOINT` whose stack ends
//  in `_assertionFailure`. There is no `try`, no optional, and nothing to catch.
//
//  That is what issue 0065 turned out to be, after a crash report from a device that nobody could
//  reproduce for two days. `BookDetailView` deletes the copy and **stays on screen**, which is
//  deliberate: the screen is about the edition, and only the "ton exemplaire" section goes away.
//  What was missed is the inventory list *behind* it. Its cell was handed the same
//  `InventoryItem`, and a `@Model` is observable — so deleting it invalidates every view body
//  that had read one of its properties, including cells whose parent `@Query` has not published
//  its new array yet. `InventoryCell.body` runs once more, reads `item.transaction`, and traps.
//
//  **The re-render cannot be prevented from the list's side**, which is why this is a property of
//  the model rather than a fix in one screen: a view that renders a model it does not own has to
//  be able to ask whether it is still there before reading anything off it. The four places that
//  hold an `InventoryItem` and can outlive it all ask.
//
//  **The order of the two clauses is load-bearing.** `modelContext` is asked first and
//  short-circuits: it is not backed by the store, so it still answers on an invalidated object,
//  where `isDeleted` is not guaranteed to. Between `delete(_:)` and the `save()` that follows,
//  the context is still set and `isDeleted` is what says so; after the save, the context is nil.
//
//  A model that was never inserted answers `false` too, which is correct for every caller here —
//  none of them is handed a draft.
//
//  See ADR 0001, and `docs/features/0012-end-to-end-scenario.md`, whose deletion step is what
//  finally reproduced the crash.
//

import SwiftData

extension PersistentModel {

    /// Whether this model still has a row behind it: registered in a context, and not deleted.
    ///
    /// Ask it before reading any persisted property of a model this view does not own — the read
    /// is a hard trap once the row is gone, not an optional that comes back nil.
    var isStillInTheStore: Bool {
        modelContext != nil && isDeleted == false
    }
}
