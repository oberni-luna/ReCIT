//
//  ShelfModelAddItemsTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 06/11/2026.
//
//  Filing several books onto an étagère at once, as the v2 « Ajouter des livres » sheet does:
//  one `add-items` call carrying only the books not on it yet, the books on the shelf before the
//  server answers, and off it again if the server refuses. Network is mocked.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("ShelfModel.addItems", .serialized)
struct ShelfModelAddItemsTests {
    private func makeItems(
        _ ids: [String],
        in context: ModelContext
    ) -> [InventoryItem] {
        ids.map { id in
            let item: InventoryItem = Fixture.inventoryItem(
                id: id,
                edition: Fixture.edition(uri: "isbn:\(id)")
            )
            context.insert(item)
            return item
        }
    }

    private func membershipJSON(_ ids: [String]) -> String {
        let items: String = ids.map { "\"\($0)\"" }.joined(separator: ",")
        return #"{"shelves":{"shelf-1":{"_id":"shelf-1","items":[\#(items)]}}}"#
    }

    @Test
    func `files only the books not on the étagère yet, in one call, before the server answers`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("add-items", json: membershipJSON(["a", "b", "c"]))
        let model: ShelfModel = .init(apiService: mock)
        let shelf: Shelf = .mock()
        context.insert(shelf)
        let items: [InventoryItem] = makeItems(["a", "b", "c"], in: context)
        shelf.items.append(items[0])

        model.addItems(items, to: shelf, modelContext: context)

        #expect(Set(shelf.items.map(\._id)) == ["a", "b", "c"])

        await model.inFlightTask?.value

        let payload: ShelfItemsDTO = try JSONDecoder().decode(
            ShelfItemsDTO.self,
            from: try #require(mock.sentPayloads.first)
        )
        #expect(mock.sentPayloads.count == 1)
        #expect(payload.items == ["b", "c"])
        #expect(Set(shelf.items.map(\._id)) == ["a", "b", "c"])
    }

    @Test
    func `takes the books it added off again when the server refuses`() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("add-items", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: ShelfModel = .init(apiService: mock, errorReporter: reporter)
        let shelf: Shelf = .mock()
        context.insert(shelf)
        let items: [InventoryItem] = makeItems(["a", "b", "c"], in: context)
        shelf.items.append(items[0])

        model.addItems(items, to: shelf, modelContext: context)
        await model.inFlightTask?.value

        #expect(shelf.items.map(\._id) == ["a"])
        #expect(reporter.lastFailure != nil)
    }
}
