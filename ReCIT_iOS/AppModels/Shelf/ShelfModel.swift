//
//  ShelfModel.swift
//  ReCIT_iOS
//
//  Syncs the current user's inventaire.io shelves into SwiftData, and owns the writes
//  that go the other way: creating, renaming and deleting an étagère, and putting a
//  book on one or taking it off. Deleting only ever removes the shelf — the books it
//  held stay in the inventory. See issue 0021.
//
//  Both writes come in two flavours: the optimistic, fire-and-forget one the menus
//  use, and an awaiting one for the auto-sort apply, which has to know per étagère
//  whether the write landed before it ticks it off. See PRD 0006.
//
//  Two passes: (1) `by-owners` upserts shelf metadata; (2) `by-ids&with-items`
//  rebuilds the `Shelf ⇄ InventoryItem` relation from server membership. The second
//  pass links whatever items already exist locally, so membership stays correct even
//  when the gated inventory sync skips (its own linking only runs on a real refresh).
//  See ADR 0003.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ShelfModel: OptimisticMutating {

    /// DEV: when true, shelf membership is faked by distributing the user's own items
    /// across their shelves, so the bookshelf UI can be validated independently of the
    /// `/api/shelves` membership call. Now using real server membership.
    static let useFakeMembership: Bool = false

    private let apiService: APIServicing

    /// Shared channel used to surface a background failure to the UI.
    var errorReporter: AppErrorReporter?

    /// Most recent optimistic background task, exposed so tests can await it.
    @ObservationIgnored private(set) var inFlightTask: Task<Void, Never>?

    /// Raised while an optimistic membership write is waiting on the server.
    ///
    /// The `Shelf ⇄ InventoryItem` relation has two independent *wholesale* writers —
    /// `linkItems` below and `InventoryModel.syncInventory`'s per-item assignment — and
    /// both replace it outright with server state that is one round-trip behind. A sync
    /// landing in that window would visibly take the book back off the étagère the user
    /// just put it on, so both writers stand down until the write settles. App-scoped
    /// rather than instance-scoped because the two writers live in two different models.
    /// Derived from `membershipWriteDepth` rather than assigned, so overlapping writes
    /// cannot open the gate on each other. See PRD 0004.
    private(set) static var isMembershipWriteInFlight: Bool = false

    /// How many membership writes are outstanding. A depth rather than a flag because
    /// the auto-sort apply issues one write per étagère in a row (PRD 0006): a
    /// menu-driven single-book write settling inside that run would otherwise lower
    /// the gate while the run is still going, and a sync would take the books back off
    /// the étagère they had just been filed onto.
    private static var membershipWriteDepth: Int = 0

    private static func raiseMembershipGate() {
        membershipWriteDepth += 1
        isMembershipWriteInFlight = true
    }

    private static func lowerMembershipGate() {
        membershipWriteDepth = max(0, membershipWriteDepth - 1)
        isMembershipWriteInFlight = membershipWriteDepth > 0
    }

    init(apiService: APIServicing, errorReporter: AppErrorReporter? = nil) {
        self.apiService = apiService
        self.errorReporter = errorReporter
    }

    /// Optimistically creates a shelf: a placeholder appears at once (slotting into the
    /// A→Z order), the `POST` runs in the background, and on success the placeholder is
    /// swapped for the server's canonical shelf. On failure it's removed and the error
    /// surfaced. Visibility defaults to private server-side. See ADR 0003 / 0004.
    func createShelf(name: String, description: String, visibility: [String], ownerId: String, modelContext: ModelContext) {
        let placeholder: Shelf = .init(
            _id: OptimisticID.make(),
            _rev: "",
            name: name,
            slug: "",
            shelfDescription: description,
            ownerId: ownerId,
            visibility: visibility,
            colorHex: nil,
            created: .now,
            updated: nil
        )

        inFlightTask = optimistic(
            modelContext,
            apply: { modelContext.insert(placeholder) },
            revert: { modelContext.delete(placeholder) },
            request: { [weak self] in
                guard let self else { return }
                let payload: NewShelfDTO = .init(name: name, description: description.isEmpty ? nil : description, visibility: visibility)
                guard let response: ShelfResponseDTO = try await self.apiService.send(
                    toEndpoint: "/api/shelves?action=create",
                    method: "POST",
                    payload: payload,
                    debug: true
                ) else {
                    throw NetworkError.badResponse
                }
                // Reconcile: swap the placeholder for the server's canonical shelf.
                modelContext.delete(placeholder)
                modelContext.insert(Shelf(dto: response.shelf))
            }
        )
    }

    /// Optimistically updates a shelf's editable attributes (name, description,
    /// visibility): applies locally at once, PUTs in the background, reverts on failure.
    func updateShelf(_ shelf: Shelf, name: String, description: String, visibility: [String], modelContext: ModelContext) {
        let previousName: String = shelf.name
        let previousDescription: String = shelf.shelfDescription
        let previousVisibility: [String] = shelf.visibility

        inFlightTask = optimistic(
            modelContext,
            apply: {
                shelf.name = name
                shelf.shelfDescription = description
                shelf.visibility = visibility
            },
            revert: {
                shelf.name = previousName
                shelf.shelfDescription = previousDescription
                shelf.visibility = previousVisibility
            },
            request: { [weak self] in
                guard let self else { return }
                let payload: UpdateShelfDTO = .init(
                    shelf: shelf._id,
                    name: name,
                    description: description,
                    visibility: visibility
                )
                guard let response: ShelfResponseDTO = try await self.apiService.send(
                    toEndpoint: "/api/shelves?action=update",
                    method: "POST",
                    payload: payload,
                    debug: true
                ) else {
                    throw NetworkError.badResponse
                }
                shelf.update(from: response.shelf)
            }
        )
    }

    /// Optimistically deletes an étagère: it leaves the carousel at once, the `POST` runs
    /// in the background, and on failure the shelf comes back exactly as it was — books
    /// included — with the error surfaced.
    ///
    /// **The shelf goes, the books stay.** `Shelf.items` nullifies rather than cascades, so
    /// deleting the shelf only unhooks the relation: every copy stays in the inventory and
    /// on every other étagère it sits on. The server's `with-items` flag, which would take
    /// the books too, is not part of `DeleteShelvesDTO` at all.
    ///
    /// Its own path rather than `membershipWrite`'s: the payload is `ids`, not `id` plus
    /// `items`, there is nothing to reconcile once the shelf is gone, and the membership
    /// gate would buy nothing here — the sync pass it guards looks each shelf up locally
    /// and skips the ones that no longer resolve.
    ///
    /// Deletion is the one write that cannot revert by inverting itself: SwiftData
    /// invalidates the deleted object, so the shelf is snapshotted *before* `apply` and a
    /// fresh one is inserted under the same `_id` on failure. The books survive the delete
    /// untouched, so re-attaching them restores membership — the relation declares its
    /// inverse, so assigning on the shelf side moves the item side back too.
    ///
    /// This departs from ADR 0001's server-first exception for deletes, the way ADR 0004
    /// already did for creates: the carousel is the app's identity and a shelf lingering on
    /// it for a round-trip after the user confirmed reads as a failed delete.
    func deleteShelf(_ shelf: Shelf, modelContext: ModelContext) {
        let shelfId: String = shelf._id
        let items: [InventoryItem] = shelf.items
        let snapshot: Shelf = .init(
            _id: shelf._id,
            _rev: shelf._rev,
            name: shelf.name,
            slug: shelf.slug,
            shelfDescription: shelf.shelfDescription,
            ownerId: shelf.ownerId,
            visibility: shelf.visibility,
            colorHex: shelf.colorHex,
            created: shelf.created,
            updated: shelf.updated
        )

        inFlightTask = optimistic(
            modelContext,
            apply: { modelContext.delete(shelf) },
            revert: {
                modelContext.insert(snapshot)
                snapshot.items = items
            },
            request: { [weak self] in
                guard let self else { return }
                let payload: DeleteShelvesDTO = .init(ids: [shelfId])
                // Answers `{ ok, shelves }`; the shelves it echoes describe what was just
                // removed, so there is nothing left to merge back in.
                guard let _: OkStatusDTO = try await self.apiService.send(
                    toEndpoint: "/api/shelves?action=delete",
                    method: "POST",
                    payload: payload,
                    debug: true
                ) else {
                    throw NetworkError.badResponse
                }
            }
        )
    }

    /// Optimistically files an item onto an étagère: the relation is mutated and saved at
    /// once, so the shelf card fills in before the network is touched, then the write runs
    /// in a model-owned background task and the server's post-write membership is
    /// reconciled back in. On failure the book comes off again and the error is surfaced.
    ///
    /// The relation declares its inverse, so appending on the shelf side moves the item
    /// side too; a book may sit on several étagères at once. Already-filed items are a
    /// no-op — the menu never offers them, this only guards against a double tap.
    /// See ADR 0001 / PRD 0004.
    func addItem(_ item: InventoryItem, to shelf: Shelf, modelContext: ModelContext) {
        let itemId: String = item._id
        guard shelf.items.contains(where: { $0._id == itemId }) == false else { return }

        membershipWrite(
            modelContext,
            action: "add-items",
            shelf: shelf,
            itemId: itemId,
            apply: { shelf.items.append(item) },
            revert: { shelf.items.removeAll { $0._id == itemId } }
        )
    }

    /// Optimistically takes an item off an étagère: the book leaves the shelf on screen
    /// before the network is touched, the write runs in a model-owned background task, and
    /// the server's post-write membership is reconciled back in. On failure the book goes
    /// back where it was and the error is surfaced.
    ///
    /// Membership only — the copy stays in the inventory, and the other étagères it sits
    /// on are untouched, because only this shelf's side of the relation is edited. Items
    /// the shelf doesn't hold are a no-op — the menu never offers them, this only guards
    /// against a double tap. See ADR 0001 / PRD 0004.
    func removeItem(_ item: InventoryItem, from shelf: Shelf, modelContext: ModelContext) {
        let itemId: String = item._id
        guard shelf.items.contains(where: { $0._id == itemId }) else { return }

        membershipWrite(
            modelContext,
            action: "remove-items",
            shelf: shelf,
            itemId: itemId,
            apply: { shelf.items.removeAll { $0._id == itemId } },
            revert: { shelf.items.append(item) }
        )
    }

    /// The half both membership actions share: `add-items` and `remove-items` take the
    /// same payload and answer with the same shape, so only the local mutation and the
    /// action name differ. Kept in one place so the two directions cannot drift apart —
    /// above all on the gate, whose window is easy to get subtly wrong.
    ///
    /// The gate stays raised for the whole cycle, revert included (the runner performs it
    /// after `request` has thrown): both wholesale writers of this relation would
    /// otherwise replace the user's change with server state one round-trip behind.
    private func membershipWrite(
        _ modelContext: ModelContext,
        action: String,
        shelf: Shelf,
        itemId: String,
        apply: () -> Void,
        revert: @escaping () -> Void
    ) {
        Self.raiseMembershipGate()

        let cycle: Task<Void, Never> = optimistic(
            modelContext,
            apply: apply,
            revert: revert,
            request: { [weak self] in
                guard let self else { return }
                try await self.sendMembership(
                    action: action,
                    shelf: shelf,
                    itemIds: [itemId],
                    modelContext: modelContext
                )
            }
        )

        inFlightTask = Task {
            await cycle.value
            Self.lowerMembershipGate()
        }
    }

    /// The membership call itself, and the reconcile from its answer. One
    /// implementation, shared by the optimistic single-book path above and the
    /// awaiting bulk one below, so there is exactly one place in the app that posts to
    /// `add-items` / `remove-items`.
    private func sendMembership(
        action: String,
        shelf: Shelf,
        itemIds: [String],
        modelContext: ModelContext
    ) async throws {
        let payload: ShelfItemsDTO = .init(id: shelf._id, items: itemIds)
        guard let response: ShelvesWithItemsResponseDTO = try await apiService.send(
            toEndpoint: "/api/shelves?action=\(action)",
            method: "POST",
            payload: payload,
            debug: true
        ) else {
            throw NetworkError.badResponse
        }
        // Reconcile: the response carries the étagère's membership after the write.
        // A shelf the write left empty may answer without an `items` key at all,
        // which means an empty membership and not "no news" — so the shelf is
        // emptied rather than left holding the book it just lost.
        guard let dto = response.shelves[shelf._id] else { return }
        shelf.items = localItems(ids: dto.items ?? [], modelContext: modelContext)
    }

    // MARK: - Awaiting writes (bulk apply)

    /// Creates an étagère and **waits** for the server to confirm it, answering with the
    /// canonical shelf so the caller can use the id the server assigned.
    ///
    /// The awaiting counterpart of `createShelf`, added alongside it rather than
    /// replacing it. It exists for the auto-sort apply (PRD 0006), a documented
    /// departure from ADR 0001's optimistic rule — alongside the batch scanner's add,
    /// for the same reason: the user has just approved a large mutation and has to be
    /// able to trust what landed. Eight étagères appearing instantly and then some of
    /// them silently vanishing is the failure being avoided. There is no placeholder to
    /// swap either, because the caller cannot take its second step without the server's
    /// id, so there would be nothing to gain by guessing one.
    func createShelfAwaitingServer(
        name: String,
        description: String,
        visibility: [String],
        modelContext: ModelContext
    ) async throws -> Shelf {
        let payload: NewShelfDTO = .init(
            name: name,
            description: description.isEmpty ? nil : description,
            visibility: visibility
        )
        guard let response: ShelfResponseDTO = try await apiService.send(
            toEndpoint: "/api/shelves?action=create",
            method: "POST",
            payload: payload,
            debug: true
        ) else {
            throw NetworkError.badResponse
        }

        let shelf: Shelf = .init(dto: response.shelf)
        modelContext.insert(shelf)
        try modelContext.save()
        return shelf
    }

    /// Files several items onto an étagère in one `add-items` call and **waits** for the
    /// server's answer.
    ///
    /// The awaiting counterpart of `addItem`, which is optimistic and fire-and-forget by
    /// design: that fits a menu tap on one book, but a sequenced bulk apply has to know
    /// per étagère whether the write landed before it ticks that étagère off and moves
    /// to the next one. Same endpoint, same payload, same reconcile — only the waiting
    /// differs, which is why the call lives in `sendMembership` and is shared.
    ///
    /// Server first, then the relation from the server's own answer: waiting is the
    /// point here, so there is nothing to apply early and nothing to revert on failure.
    /// Items the shelf already holds are dropped from the payload, and an empty payload
    /// is a no-op — which is what makes calling this twice for the same books harmless.
    func addItemsAwaitingServer(
        _ items: [InventoryItem],
        to shelf: Shelf,
        modelContext: ModelContext
    ) async throws {
        let alreadyOnShelf: Set<String> = .init(shelf.items.map(\._id))
        let itemIds: [String] = items.map(\._id).filter { !alreadyOnShelf.contains($0) }
        guard itemIds.isEmpty == false else { return }

        Self.raiseMembershipGate()
        defer { Self.lowerMembershipGate() }

        try await sendMembership(
            action: "add-items",
            shelf: shelf,
            itemIds: itemIds,
            modelContext: modelContext
        )
        try modelContext.save()
    }

    func syncShelves(forUser: User, modelContext: ModelContext) async throws {
        // 1. Shelf metadata (name, colour, …), upserted in place.
        let response: ShelvesResponseDTO? = try await apiService.fetchData(
            fromEndpoint: "/api/shelves?action=by-owners&owners=\(forUser._id)"
        )
        guard let response else { return }

        let dtos: [ShelfDTO] = Array(response.shelves.values)
        try modelContext.upsert(
            dtos,
            dtoID: { $0._id },
            modelID: { (shelf: Shelf) in shelf._id },
            make: { Shelf(dto: $0) },
            update: { shelf, dto in shelf.update(from: dto) },
            deleteMissing: true
        )
        try modelContext.save()

        // 2. Membership. Stand down while a membership write is still unconfirmed: this
        // pass assigns the relation wholesale from state the server has not applied the
        // user's change to yet. See PRD 0004.
        guard Self.isMembershipWriteInFlight == false else { return }

        if Self.useFakeMembership {
            applyFakeMembership(ownerId: forUser._id, modelContext: modelContext)
        } else {
            // Rebuild the relation from the authoritative server list of items per
            // shelf. Independent of the inventory-sync gate.
            try await linkItems(shelfIds: Array(response.shelves.keys), modelContext: modelContext)
        }
    }

    /// DEV fake: spreads the user's items across their shelves with varied counts so
    /// both layouts (vertical spines ≤5, horizontal pile ≥6) are exercised. Overlap
    /// is intentional (a book can sit on several shelves).
    private func applyFakeMembership(ownerId: String, modelContext: ModelContext) {
        var itemsDescriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.created, order: .reverse)]
        )
        itemsDescriptor.fetchLimit = 40
        let items: [InventoryItem] = (try? modelContext.fetch(itemsDescriptor)) ?? []
        guard items.isEmpty == false else { return }

        let shelvesDescriptor: FetchDescriptor<Shelf> = .init(
            predicate: #Predicate { $0.ownerId == ownerId },
            sortBy: [SortDescriptor(\.name)]
        )
        let shelves: [Shelf] = (try? modelContext.fetch(shelvesDescriptor)) ?? []

        let counts: [Int] = [8, 4, 2, 6, 3]
        for (index, shelf) in shelves.enumerated() {
            let count: Int = min(counts[index % counts.count], items.count)
            shelf.items = Array(items.prefix(count))
        }
        try? modelContext.save()
    }

    private func linkItems(shelfIds: [String], modelContext: ModelContext) async throws {
        guard shelfIds.isEmpty == false else { return }

        let idsParam: String = shelfIds.joined(separator: "|")
        let withItems: ShelvesWithItemsResponseDTO? = try await apiService.fetchData(
            fromEndpoint: "/api/shelves?action=by-ids&ids=\(idsParam)&with-items=true"
        )
        guard let withItems else { return }

        for (shelfId, dto) in withItems.shelves {
            guard let shelf = localShelf(id: shelfId, modelContext: modelContext) else { continue }
            shelf.items = localItems(ids: dto.items ?? [], modelContext: modelContext)
        }
        try modelContext.save()
    }

    private func localShelf(id: String, modelContext: ModelContext) -> Shelf? {
        let descriptor: FetchDescriptor<Shelf> = .init(predicate: #Predicate { $0._id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func localItems(ids: [String], modelContext: ModelContext) -> [InventoryItem] {
        guard ids.isEmpty == false else { return [] }
        let descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: #Predicate { ids.contains($0._id) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
