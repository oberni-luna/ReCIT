//
//  SortSessionModel.swift
//  ReCIT_iOS
//
//  The sorting screen's state: the opening sync, the frozen snapshot it produces, and
//  the change stack laid on top of it. Everything the screen renders comes back out
//  through `projection`, which is pure.
//
//  Owned by the view for now (`@State`), not injected app-wide. PRD 0008 makes the
//  session app-scoped so a running apply and the ledger of what it wrote outlive the
//  screen — but nothing is written in this slice, so there is nothing yet to outlive
//  it, and an app-scoped model would only add a lifetime nobody needs. Slice 0040
//  lifts it into `RootView` when the writes arrive.
//
//  See PRD 0008.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class SortSessionModel {

    enum Phase: Equatable {
        /// The opening sync is running. The screen shows a progress indicator: the
        /// user is about to rearrange their library and must not be doing it against
        /// a stale one.
        case syncing
        /// The snapshot is frozen and the surface is usable.
        case ready
    }

    private(set) var phase: Phase = .syncing

    private(set) var snapshot: SortSnapshot = .empty

    /// The ordered changes laid over the snapshot. Always empty in this slice —
    /// slice 0038's drag gesture is what fills it.
    private(set) var changes: [SortChange] = []

    /// What the screen draws. Recomputed on every read rather than cached: it is a
    /// walk over a few hundred books, and a cache is one more thing that can
    /// disagree with the stack.
    var projection: SortProjection {
        .init(snapshot: snapshot, changes: changes)
    }

    /// **The button rule, derived — no "has applied" flag.** A non-empty stack means
    /// the apply button is live and the third button says « Annuler »; an empty one
    /// means the apply button is inert and the third says « Terminer » and closes.
    /// A successful apply empties the stack, so the label changes on its own, and
    /// taking sorting up again changes it back — which is true, because there is once
    /// more something to discard. A sticky flag would leave the screen's only
    /// destructive button labelled « Terminer ».
    var hasPendingChanges: Bool { changes.isEmpty == false }

    /// Reads the library, once. Syncs first so the user is not rearranging a stale
    /// collection, then freezes.
    ///
    /// Sync failures are reported and swallowed: the store still holds the last known
    /// library, and refusing to open the screen because the network is down would be
    /// worse than sorting a slightly old one — nothing is written here anyway.
    func load(
        user: User,
        shelfModel: ShelfModel,
        inventoryModel: InventoryModel,
        errorReporter: AppErrorReporter?,
        modelContext: ModelContext
    ) async {
        guard phase == .syncing else { return }

        // Shelves before inventory: an item resolves its shelf membership against
        // `Shelf` objects that have to exist by then. See ADR 0003.
        do {
            try await shelfModel.syncShelves(forUser: user, modelContext: modelContext)
            try await inventoryModel.syncInventory(forUser: user, modelContext: modelContext)
        } catch {
            errorReporter?.report(error)
        }

        freeze(user: user, modelContext: modelContext)
        phase = .ready
    }

    /// Throws the stack away. Not reachable in this slice — the stack is always
    /// empty — but it is the other half of the derived button rule, and writing it
    /// now is what lets slice 0038 change nothing here.
    func discardChanges() {
        changes = []
    }

    /// **Reads SwiftData exactly once, into value types, and never looks again.**
    ///
    /// This is a deliberate departure from ADR 0001, which binds the UI to SwiftData
    /// and keeps it reactive. That rule is right for a screen that *displays* the
    /// library; this one holds a **draft** of it. `ShelfModel`'s membership gate only
    /// stands syncs down while a write is in flight, so across a sorting session
    /// lasting minutes any sync triggered elsewhere — a pull-to-refresh on another
    /// tab, a background refresh — would reassign the whole `Shelf ⇄ InventoryItem`
    /// relation from server state and move books out from under the user's fingers,
    /// undoing gestures they had already made.
    ///
    /// Freezing also makes `SortProjection` a pure function of two value types, which
    /// is what makes the rule "every book is in exactly one section" testable without
    /// a store.
    ///
    /// So: do **not** turn this into a `@Query`. If reactivity is ever wanted here, it
    /// has to arrive as an explicit "the library changed — reload?" affordance, not as
    /// a live binding.
    private func freeze(user: User, modelContext: ModelContext) {
        let ownerId: String = user._id

        let shelfDescriptor: FetchDescriptor<Shelf> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.name)]
        )
        let shelves: [Shelf] = (try? modelContext.fetch(shelfDescriptor)) ?? []

        let itemDescriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.created, order: .reverse)]
        )
        let items: [InventoryItem] = (try? modelContext.fetch(itemDescriptor)) ?? []

        snapshot = .init(
            shelves: shelves.map { shelf in
                .init(
                    id: shelf._id,
                    name: shelf.name,
                    bookIds: shelf.items.map(\._id)
                )
            },
            books: items.map(Self.book(from:))
        )
    }

    /// One copy as the surface needs it. Reuses `AutoSortBook` rather than declaring
    /// a second book value type: the AI proposal (slice 0042) produces an
    /// `AutoSortPlan` over exactly these, so sharing the type is what keeps that
    /// conversion a rename rather than a mapping.
    ///
    /// A copy's genres are the union of the genres of the works behind its edition, in
    /// claim order and deduplicated — the same reading `AutoSortModel` does, so the
    /// genre line under a book says the same thing on both screens.
    private static func book(from item: InventoryItem) -> AutoSortBook {
        var seen: Set<String> = []
        let genres: [String] = (item.edition?.works ?? [])
            .flatMap(\.genres)
            .filter { seen.insert($0).inserted }

        return .init(
            id: item._id,
            title: item.edition?.title ?? "",
            authors: item.edition?.authorNames.joined(separator: ", ") ?? "",
            coverImageUrl: item.edition?.image,
            genres: genres
        )
    }
}
