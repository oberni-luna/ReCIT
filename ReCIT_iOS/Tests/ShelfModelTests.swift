//
//  ShelfModelTests.swift
//  ReCIT_iOSTests
//
//  Behavioural tests for the optimistic shelf creation: placeholder appears at once,
//  reconciles to the server shelf on success, reverts on failure. Network is mocked.
//  See ADR 0004 / PRD 0001.
//
//  And for what `syncShelves` is allowed to delete: `by-owners` only answers for the
//  owners it was asked about, so its delete pass has to be scoped to them. Unscoped, the
//  first sync of a friend's étagères would read mine as gone. See issue 0090.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("ShelfModel", .serialized)
struct ShelfModelTests {

    /// One `by-owners` answer: the id-keyed dict `syncShelves` decodes.
    private func shelvesByOwnerJSON(id: String, name: String, owner: String) -> String {
        """
        {
          "shelves": {
            "\(id)": {
              "_id": "\(id)",
              "_rev": "1-abc",
              "name": "\(name)",
              "slug": "\(name.lowercased())",
              "description": "",
              "owner": "\(owner)",
              "visibility": ["friends"],
              "color": null,
              "created": 1700000000000,
              "updated": null
            }
          }
        }
        """
    }

    private func shelf(id: String, name: String, owner: String) -> Shelf {
        .init(
            _id: id,
            _rev: "1-abc",
            name: name,
            slug: name.lowercased(),
            shelfDescription: "",
            ownerId: owner,
            visibility: ["friends"],
            colorHex: nil,
            created: .init(timeIntervalSince1970: 0),
            updated: nil
        )
    }

    private func shelfJSON(id: String, name: String) -> String {
        """
        {
          "shelf": {
            "_id": "\(id)",
            "_rev": "1-abc",
            "name": "\(name)",
            "slug": "\(name.lowercased())",
            "description": "",
            "owner": "user-1",
            "visibility": [],
            "color": null,
            "created": 1700000000000,
            "updated": null
          }
        }
        """
    }

    @Test("createShelf inserts an optimistic placeholder, then reconciles to the server shelf")
    func createReconciles() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/shelves", json: shelfJSON(id: "shelf-1", name: "Lus"))
        let model: ShelfModel = .init(apiService: mock)

        model.createShelf(name: "Lus", description: "", visibility: [], ownerId: "user-1", modelContext: context)

        // Optimistic: a placeholder exists immediately with an optimistic id.
        let immediate: [Shelf] = try context.fetch(FetchDescriptor<Shelf>())
        #expect(immediate.count == 1)
        #expect(OptimisticID.isOptimistic(immediate.first?._id ?? ""))

        await model.inFlightTask?.value

        // Reconciled: the placeholder is replaced by the server's canonical shelf.
        let after: [Shelf] = try context.fetch(FetchDescriptor<Shelf>())
        #expect(after.count == 1)
        #expect(after.first?._id == "shelf-1")
        #expect(after.first?.name == "Lus")
    }

    @Test("createShelf reverts the placeholder when the request fails")
    func createRevertsOnFailure() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/shelves", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: ShelfModel = .init(apiService: mock, errorReporter: reporter)

        model.createShelf(name: "Lus", description: "", visibility: [], ownerId: "user-1", modelContext: context)
        #expect(try context.fetch(FetchDescriptor<Shelf>()).count == 1)

        await model.inFlightTask?.value

        // Reverted: nothing persists after a failed create.
        #expect(try context.fetch(FetchDescriptor<Shelf>()).isEmpty)
    }

    // MARK: - Sync scope (issue 0090)

    @Test("syncShelves leaves another owner's étagères alone")
    func syncDoesNotDeleteAnotherOwnersShelves() async throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(shelf(id: "mine-1", name: "Lus", owner: "user-1"))
        context.insert(shelf(id: "theirs-old", name: "Anciens", owner: "user-2"))
        try context.save()

        let mock: MockAPIService = .init()
        // The friend now has one étagère, and it is not the one we held for them.
        mock.stub("action=by-owners", json: shelvesByOwnerJSON(id: "theirs-1", name: "Polars", owner: "user-2"))
        mock.stub("action=by-ids", json: #"{ "shelves": { "theirs-1": { "_id": "theirs-1", "items": [] } } }"#)
        let model: ShelfModel = .init(apiService: mock)

        let friend: User = Fixture.user(id: "user-2", username: "friend")
        context.insert(friend)
        try await model.syncShelves(forUser: friend, modelContext: context)

        let ids: Set<String> = .init(try context.fetch(FetchDescriptor<Shelf>()).map(\._id))
        // Mine survives a sync it was never part of…
        #expect(ids.contains("mine-1"))
        // …the friend's new étagère arrives…
        #expect(ids.contains("theirs-1"))
        // …and the friend's étagère the server no longer lists is the one that goes.
        #expect(ids.contains("theirs-old") == false)
    }
}
