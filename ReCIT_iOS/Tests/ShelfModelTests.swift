//
//  ShelfModelTests.swift
//  ReCIT_iOSTests
//
//  Behavioural tests for the optimistic shelf creation: placeholder appears at once,
//  reconciles to the server shelf on success, reverts on failure. Network is mocked.
//  See ADR 0004 / PRD 0001.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("ShelfModel", .serialized)
struct ShelfModelTests {

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
}
