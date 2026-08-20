//
//  SortSessionModel.swift
//  ReCIT_iOS
//
//  The sorting session: the opening sync, the frozen snapshot it produces, and the
//  ordered stack of changes laid on top of it. Everything the screen renders comes
//  back out through `projection`, which is pure.
//
//  **App-scoped**, built in `RootView` and injected like every other model. Slice 0040
//  writes from here, and those writes — plus the ledger that says what landed — have
//  to outlive the screen: a user who navigates away mid-apply must find the account of
//  it when they come back. The consequence lands one slice early, in this one: a stack
//  built by dragging survives leaving the screen, which is exactly what the user
//  expects of a draft they have not saved.
//
//  Being app-scoped makes `load` a *resume* as much as an open — see its note.
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

    /// The ordered changes laid over the snapshot. Ordered rather than merged, so the
    /// coalescing the write plan does (slice 0040) — and any undo — stays a pure
    /// function of the stack alone.
    private(set) var changes: [SortChange] = []

    /// Guards against two appearances of the screen syncing over each other. Not a
    /// phase: a load that is already running is not a state the screen renders
    /// differently, it is a call that must not happen twice.
    private var isLoading: Bool = false

    /// What the screen draws. Recomputed on every read rather than cached: it is a
    /// walk over a few hundred books, and a cache is one more thing that can
    /// disagree with the stack.
    var projection: SortProjection {
        .init(snapshot: snapshot, changes: changes)
    }

    /// What applying would do: the operations to send, each étagère's status, and the
    /// counts the recap reads from. Recomputed on every read, like `projection` and for
    /// the same reason — a cached plan is one more thing that can disagree with the
    /// stack, and disagreeing is precisely what a single reduction exists to prevent.
    var writePlan: SortWritePlan {
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

    /// Opens the session — or resumes the one already in hand.
    ///
    /// **A session with pending changes is resumed, never re-read.** The user left this
    /// screen holding a draft of their library; coming back has to find it exactly as
    /// they left it, and a fresh snapshot underneath a stack built against the old one
    /// would move books out from under changes that named them. With nothing pending
    /// there is nothing to protect, so the library is re-synced and re-frozen — which
    /// is what keeps a second visit from sorting a stale collection.
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
        guard isLoading == false else { return }
        guard changes.isEmpty else {
            phase = .ready
            return
        }

        isLoading = true
        phase = .syncing
        defer { isLoading = false }

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

    /// Records one drop: the book leaves the section it was dragged from for the one it
    /// was dropped on.
    ///
    /// A book dropped back on the section it came from records **nothing**. A change
    /// that changes nothing would still make the apply button live and turn
    /// « Terminer » into « Annuler » — the screen would be claiming there is work to
    /// discard when there is none. The rule itself lives on `SortChange.move`, which is
    /// pure and therefore assertable; this method only appends what comes back.
    func moveBook(
        _ bookId: String,
        from origin: SortSection.ID,
        to destination: SortSection.ID
    ) {
        guard let change = SortChange.move(bookId: bookId, from: origin, to: destination) else { return }
        changes.append(change)
    }

    /// Throws the stack away and hands the screen back its snapshot. The other half of
    /// the derived button rule: with a non-empty stack the third button says
    /// « Annuler » and this is what it does.
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
