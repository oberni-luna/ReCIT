//
//  ListModelTests.swift
//  ReCIT_iOSTests
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("ListModel", .serialized)
struct ListModelTests {

    private func newListJSON(id: String, name: String) -> String {
        """
        {
          "list": {
            "_id": "\(id)",
            "_rev": "1-abc",
            "name": "\(name)",
            "description": "desc",
            "created": 1700000000,
            "updated": null,
            "visibility": ["public"],
            "type": "work",
            "elements": []
          }
        }
        """
    }

    @Test("createList persists the returned list")
    func createListPersists() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists", json: newListJSON(id: "list-1", name: "Favourites"))
        let model: ListModel = .init(apiService: mock)

        try await model.createList(
            modelContext: context,
            name: "Favourites",
            description: "desc",
            type: "work",
            visibility: ["public"]
        )

        let stored: [EntityList] = try context.fetch(FetchDescriptor<EntityList>())
        #expect(stored.count == 1)
        #expect(stored.first?.name == "Favourites")
        #expect(stored.first?._id == "list-1")
    }

    @Test("deleteList removes the list on a successful response")
    func deleteListRemoves() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = .init(
            _id: "list-1",
            _rev: "1",
            name: "Favourites",
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            visibility: [.public],
            type: .work
        )
        context.insert(list)
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/delete", json: #"{"ok":true}"#)
        let model: ListModel = .init(apiService: mock)

        try await model.deleteList(modelContext: context, list: list)

        let stored: [EntityList] = try context.fetch(FetchDescriptor<EntityList>())
        #expect(stored.isEmpty)
    }

    private func makeList(context: ModelContext) throws -> EntityList {
        let list: EntityList = .init(
            _id: "l1",
            _rev: "1",
            name: "L",
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            visibility: [.public],
            type: .work
        )
        context.insert(list)
        try context.save()
        return list
    }

    @Test("addEntitiesToList shows a placeholder immediately, then reconciles the server element")
    func addEntitiesOptimistic() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = try makeList(context: context)

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/add-elements", json: #"{"ok":true,"createdElements":[{"_id":"e1","_rev":"1","list":"l1","uri":"wd:Q1","ordinal":"0","created":1700000000000,"updated":null,"comment":null}]}"#)
        let reporter: AppErrorReporter = .init()
        let model: ListModel = .init(apiService: mock, errorReporter: reporter)

        model.addEntitiesToList(modelContext: context, list: list, entityUris: ["wd:Q1"])
        #expect(list.elements.count == 1) // optimistic placeholder
        #expect(list.elements.first.map { OptimisticID.isOptimistic($0._id) } == true)

        await model.inFlightTask?.value
        #expect(list.elements.count == 1)
        #expect(list.elements.first?._id == "e1") // reconciled to server id
        #expect(reporter.lastFailure == nil)
    }

    @Test("addEntitiesToList removes the placeholder and surfaces an error on failure")
    func addEntitiesReverts() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = try makeList(context: context)

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/add-elements", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: ListModel = .init(apiService: mock, errorReporter: reporter)

        model.addEntitiesToList(modelContext: context, list: list, entityUris: ["wd:Q1"])
        #expect(list.elements.count == 1) // optimistic

        await model.inFlightTask?.value
        #expect(list.elements.isEmpty)     // reverted
        #expect(reporter.lastFailure != nil)
    }
}
