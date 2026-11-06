//
//  InventoryModelTests.swift
//  ReCIT_iOSTests
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("InventoryModel", .serialized)
struct InventoryModelTests {

    private func itemResponseJSON(id: String) -> String {
        """
        {
          "item": {
            "_id": "\(id)",
            "_rev": "1-abc",
            "entity": "isbn:9782072965821",
            "transaction": "inventorying",
            "details": null,
            "visibility": ["public"],
            "owner": "user-1",
            "created": 1700000000000,
            "updated": null,
            "busy": null,
            "snapshot": { "entity:title": "Test Book" }
          }
        }
        """
    }

    @Test("postNewItem persists and returns the created item")
    func postNewItemPersists() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let user: User = Fixture.user()
        context.insert(user)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items", json: itemResponseJSON(id: "new-item"))
        let model: InventoryModel = .init(apiService: mock)

        let created: InventoryItem = try await model.postNewItem(
            modelContext: context,
            entityUri: "isbn:9782072965821",
            transaction: .inventorying,
            visibility: [.public],
            forUser: user
        )

        #expect(created._id == "new-item")
        let stored: [InventoryItem] = try context.fetch(FetchDescriptor<InventoryItem>())
        #expect(stored.contains { $0._id == "new-item" })
    }

    @Test("removeItem deletes the item after a successful server response")
    func removeItemDeletes() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "del-1", edition: Fixture.edition(uri: "isbn:1"))
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/delete", json: #"{"ok":true}"#)
        let model: InventoryModel = .init(apiService: mock)

        try await model.removeItem(item, modelContext: context)

        let stored: [InventoryItem] = try context.fetch(FetchDescriptor<InventoryItem>())
        #expect(stored.isEmpty)
    }

    @Test("postNewItem surfaces network errors")
    func postNewItemPropagatesError() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let user: User = Fixture.user()
        context.insert(user)

        let mock: MockAPIService = .init()
        mock.stub("/api/items", error: NetworkError.badStatus(code: 500, message: nil))
        let model: InventoryModel = .init(apiService: mock)

        await #expect(throws: NetworkError.self) {
            _ = try await model.postNewItem(
                modelContext: context,
                entityUri: "isbn:1",
                transaction: .inventorying,
                visibility: [.public],
                forUser: user
            )
        }
    }

    @Test
    func `a comment is kept locally at once, then confirmed`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/bulk-update", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let model: InventoryModel = .init(apiService: mock, errorReporter: reporter)

        model.updateItemTextOptimistic(item: item, attribute: .details, text: "new notes", modelContext: context)
        #expect(item.details == "new notes") // instant

        await model.inFlightTask?.value
        #expect(item.details == "new notes")
        #expect(reporter.lastFailure == nil)
    }

    @Test
    func `a refused comment goes back to the previous one`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        item.details = "old notes"
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/bulk-update", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: InventoryModel = .init(apiService: mock, errorReporter: reporter)

        model.updateItemTextOptimistic(item: item, attribute: .details, text: "new notes", modelContext: context)
        #expect(item.details == "new notes") // optimistic

        await model.inFlightTask?.value
        #expect(item.details == "old notes") // reverted
        #expect(reporter.lastFailure != nil)
    }

    @Test
    func `a private note is kept locally at once, sent as notes, and leaves the comment alone`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        item.details = "my comment"
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/bulk-update", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let model: InventoryModel = .init(apiService: mock, errorReporter: reporter)

        model.updateItemTextOptimistic(item: item, attribute: .notes, text: "lent to Léa", modelContext: context)
        #expect(item.notes == "lent to Léa")

        await model.inFlightTask?.value
        let payload: Data = try #require(mock.sentPayloads.first)
        let sent: UpdateItemsDTO = try JSONDecoder().decode(UpdateItemsDTO.self, from: payload)
        #expect(sent.ids == ["i1"])
        #expect(sent.attribute == "notes")
        #expect(sent.value == "lent to Léa")
        #expect(item.notes == "lent to Léa")
        #expect(item.details == "my comment")
        #expect(reporter.lastFailure == nil)
    }

    @Test
    func `a refused private note goes back to the previous one`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        item.notes = "old note"
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/bulk-update", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: InventoryModel = .init(apiService: mock, errorReporter: reporter)

        model.updateItemTextOptimistic(item: item, attribute: .notes, text: "new note", modelContext: context)
        #expect(item.notes == "new note")

        await model.inFlightTask?.value
        #expect(item.notes == "old note")
        #expect(reporter.lastFailure != nil)
    }

    @Test
    func `a stale refusal leaves a newer private note in place`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/bulk-update", json: #"{"ok":true}"#)
        mock.onSend = { index in
            if index == 0 { throw NetworkError.badStatus(code: 500, message: nil) }
        }
        let reporter: AppErrorReporter = .init()
        let model: InventoryModel = .init(apiService: mock, errorReporter: reporter)

        model.updateItemTextOptimistic(item: item, attribute: .notes, text: "first", modelContext: context)
        let staleWrite: Task<Void, Never>? = model.inFlightTask
        model.updateItemTextOptimistic(item: item, attribute: .notes, text: "first, then more", modelContext: context)

        await staleWrite?.value
        await model.inFlightTask?.value
        #expect(item.notes == "first, then more")
        #expect(reporter.lastFailure != nil)
    }

    @Test("updateItemTransactionOptimistic persists locally immediately and confirms")
    func updateTransactionOptimistic() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/bulk-update", json: #"{"ok":true}"#)
        let reporter: AppErrorReporter = .init()
        let model: InventoryModel = .init(apiService: mock, errorReporter: reporter)

        model.updateItemTransactionOptimistic(item: item, newValue: .giving, previous: .inventorying, modelContext: context)
        #expect(item.transaction == .giving) // instant

        await model.inFlightTask?.value
        #expect(item.transaction == .giving)
        #expect(reporter.lastFailure == nil)
    }

    @Test("updateItemTransactionOptimistic reverts to the previous mode on failure")
    func updateTransactionReverts() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let item: InventoryItem = Fixture.inventoryItem(id: "i1", edition: Fixture.edition(uri: "isbn:1"))
        item.transaction = .inventorying
        context.insert(item)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/items/bulk-update", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: InventoryModel = .init(apiService: mock, errorReporter: reporter)

        model.updateItemTransactionOptimistic(item: item, newValue: .giving, previous: .inventorying, modelContext: context)
        #expect(item.transaction == .giving) // optimistic

        await model.inFlightTask?.value
        #expect(item.transaction == .inventorying) // reverted
        #expect(reporter.lastFailure != nil)
    }
}
