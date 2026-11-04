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

    private func makeElement(context: ModelContext, list: EntityList, id: String = "e1", comment: String = "") -> EntityListItem {
        let item: EntityListItem = .init(_id: id, comment: comment, uri: "wd:Q1", ordinal: "0", created: .now, itemType: .work)
        context.insert(item)
        list.elements.append(item)
        try? context.save()
        return item
    }

    @Test("updateComment writes the comment at once and keeps it once the server agrees")
    func updateCommentOptimistic() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = try makeList(context: context)
        let item: EntityListItem = makeElement(context: context, list: list, comment: "Avant")

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/update-element", json: #"{"_id":"e1","_rev":"2","list":"l1","uri":"wd:Q1","ordinal":"0","created":1700000000000,"updated":1700000001000,"comment":"Après"}"#)
        let reporter: AppErrorReporter = .init()
        let model: ListModel = .init(apiService: mock, errorReporter: reporter)

        model.updateComment(modelContext: context, item: item, comment: "Après")
        #expect(item.comment == "Après") // optimistic

        await model.inFlightTask?.value
        #expect(item.comment == "Après")
        #expect(reporter.lastFailure == nil)
    }

    @Test("updateComment puts the previous comment back and surfaces an error on failure")
    func updateCommentReverts() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = try makeList(context: context)
        let item: EntityListItem = makeElement(context: context, list: list, comment: "Avant")

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/update-element", error: NetworkError.badStatus(code: 500, message: nil))
        let reporter: AppErrorReporter = .init()
        let model: ListModel = .init(apiService: mock, errorReporter: reporter)

        model.updateComment(modelContext: context, item: item, comment: "Après")
        #expect(item.comment == "Après")

        await model.inFlightTask?.value
        #expect(item.comment == "Avant") // reverted
        #expect(reporter.lastFailure != nil)
    }

    @Test("updateComment sends nothing for an unchanged comment or an element not yet on the server")
    func updateCommentSkips() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let list: EntityList = try makeList(context: context)
        let saved: EntityListItem = makeElement(context: context, list: list, comment: "Même")
        let pending: EntityListItem = makeElement(context: context, list: list, id: OptimisticID.make())

        let mock: MockAPIService = .init()
        let model: ListModel = .init(apiService: mock)

        model.updateComment(modelContext: context, item: saved, comment: "Même")
        model.updateComment(modelContext: context, item: pending, comment: "Nouveau")

        #expect(model.inFlightTask == nil)
        #expect(pending.comment == "")
    }

    // MARK: - moveElement

    private func makeList(context: ModelContext, id: String) throws -> EntityList {
        let list: EntityList = .init(
            _id: id,
            _rev: "1",
            name: id,
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            visibility: [.public],
            type: .work
        )
        context.insert(list)
        try context.save()
        return list
    }

    private let addedJSON: String = #"{"ok":true,"createdElements":[{"_id":"e2","_rev":"1","list":"l2","uri":"wd:Q1","ordinal":"0","created":1700000000000,"updated":null,"comment":null}]}"#
    private let commentedJSON: String = #"{"_id":"e2","_rev":"2","list":"l2","uri":"wd:Q1","ordinal":"0","created":1700000000000,"updated":1700000001000,"comment":"Drôle"}"#
    private let removedJSON: String = #"{"list":{"_id":"l1","_rev":"2","name":"L","description":"","created":1700000000,"updated":null,"visibility":["public"],"type":"work","elements":[]}}"#

    @Test("moveElement adds with the comment, then takes the element out of the list it was in")
    func moveElementMoves() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let source: EntityList = try makeList(context: context, id: "l1")
        let destination: EntityList = try makeList(context: context, id: "l2")
        let item: EntityListItem = makeElement(context: context, list: source, comment: "Drôle")

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/add-elements", json: addedJSON)
        mock.stub("/api/lists/update-element", json: commentedJSON)
        mock.stub("/api/lists/remove-elements", json: removedJSON)
        let model: ListModel = .init(apiService: mock)

        try await model.moveElement(modelContext: context, item: item, from: source, to: destination)

        #expect(mock.recordedRequests.map(\.endpoint) == [
            "/api/lists/add-elements",
            "/api/lists/update-element",
            "/api/lists/remove-elements"
        ])
        #expect(source.elements.filter(\.isStillInTheStore).isEmpty)
        #expect(destination.elements.map(\._id) == ["e2"])
        #expect(destination.elements.first?.comment == "Drôle")
    }

    @Test("moveElement sends no comment when there is none")
    func moveElementWithoutComment() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let source: EntityList = try makeList(context: context, id: "l1")
        let destination: EntityList = try makeList(context: context, id: "l2")
        let item: EntityListItem = makeElement(context: context, list: source)

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/add-elements", json: addedJSON)
        mock.stub("/api/lists/remove-elements", json: removedJSON)
        let model: ListModel = .init(apiService: mock)

        try await model.moveElement(modelContext: context, item: item, from: source, to: destination)

        #expect(mock.recordedRequests.map(\.endpoint) == [
            "/api/lists/add-elements",
            "/api/lists/remove-elements"
        ])
        #expect(destination.elements.count == 1)
    }

    @Test("moveElement leaves the element where it was when the add fails")
    func moveElementAddFails() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let source: EntityList = try makeList(context: context, id: "l1")
        let destination: EntityList = try makeList(context: context, id: "l2")
        let item: EntityListItem = makeElement(context: context, list: source, comment: "Drôle")

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/add-elements", error: NetworkError.badStatus(code: 500, message: nil))
        let model: ListModel = .init(apiService: mock)

        await #expect(throws: NetworkError.self) {
            try await model.moveElement(modelContext: context, item: item, from: source, to: destination)
        }

        #expect(mock.recordedRequests.map(\.endpoint) == ["/api/lists/add-elements"])
        #expect(source.elements.map(\._id) == ["e1"])
        #expect(destination.elements.isEmpty)
    }

    @Test("moveElement keeps the element in both lists when taking it out fails")
    func moveElementRemoveFails() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let source: EntityList = try makeList(context: context, id: "l1")
        let destination: EntityList = try makeList(context: context, id: "l2")
        let item: EntityListItem = makeElement(context: context, list: source, comment: "Drôle")

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/add-elements", json: addedJSON)
        mock.stub("/api/lists/update-element", json: commentedJSON)
        mock.stub("/api/lists/remove-elements", error: NetworkError.badStatus(code: 500, message: nil))
        let model: ListModel = .init(apiService: mock)

        await #expect(throws: NetworkError.self) {
            try await model.moveElement(modelContext: context, item: item, from: source, to: destination)
        }

        #expect(source.elements.map(\._id) == ["e1"])
        #expect(destination.elements.map(\._id) == ["e2"])
        #expect(destination.elements.first?.comment == "Drôle")
    }
}
