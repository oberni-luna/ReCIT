//
//  UserModelDeleteAccountTests.swift
//  ReCIT_iOSTests
//
//  The one irreversible call the app makes. Two rules are worth a test each: a server that
//  answers `ok` leaves nothing of the account on this device, and a server that answers
//  anything else leaves *everything* — an app that wiped its copy on a failed call would have
//  the user believing an account is gone while it is still live on inventaire.io.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("UserModel.deleteAccount", .serialized)
struct UserModelDeleteAccountTests {

    /// A store with something of every kind in it: mine, a friend's, and the shared entities
    /// both point at.
    private func populatedContext() throws -> ModelContext {
        let context: ModelContext = try TestStore.makeContext()

        let me: User = Fixture.user(id: "user-1", username: "me")
        let friend: User = Fixture.user(id: "user-2", username: "friend")
        context.insert(me)
        context.insert(friend)

        let edition: Edition = Fixture.edition(uri: "isbn:9782072965821", title: "Test Book")
        context.insert(Fixture.inventoryItem(id: "item-1", ownerId: "user-1", edition: edition))
        context.insert(Fixture.inventoryItem(id: "item-2", ownerId: "user-2", edition: edition))

        try context.save()
        return context
    }

    @Test("A successful deletion leaves nothing of the account on this device")
    func successWipesTheStore() async throws {
        let context: ModelContext = try populatedContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        let model: UserModel = .init(apiService: mock)
        model.myUser = try context.fetch(FetchDescriptor<User>()).first { $0._id == "user-1" }

        try await model.deleteAccount(modelContext: context)

        #expect(try context.fetch(FetchDescriptor<User>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<InventoryItem>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Edition>()).isEmpty)
        #expect(model.myUser == nil)
    }

    @Test("The call is a DELETE on /api/user, with no body")
    func callsTheDocumentedEndpoint() async throws {
        let context: ModelContext = try populatedContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        let model: UserModel = .init(apiService: mock)

        try await model.deleteAccount(modelContext: context)

        #expect(mock.recordedRequests.count == 1)
        #expect(mock.recordedRequests.first?.endpoint == "/api/user")
        #expect(mock.recordedRequests.first?.method == "DELETE")
    }

    @Test("A failed call leaves the store untouched")
    func failureKeepsEverything() async throws {
        let context: ModelContext = try populatedContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/user", error: NetworkError.badStatus(code: 500, message: "boom"))
        let model: UserModel = .init(apiService: mock)
        let me: User? = try context.fetch(FetchDescriptor<User>()).first { $0._id == "user-1" }
        model.myUser = me

        await #expect(throws: NetworkError.self) {
            try await model.deleteAccount(modelContext: context)
        }

        #expect(try context.fetch(FetchDescriptor<User>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<InventoryItem>()).count == 2)
        #expect(model.myUser === me)
    }

    /// `{"ok":false}` is a server that answered and refused. Treated as a failure, because the
    /// account is still there — the local wipe must not run on it either.
    @Test("A server that answers ok:false is a failure, not a deletion")
    func refusedDeletionKeepsEverything() async throws {
        let context: ModelContext = try populatedContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":false}"#)
        let model: UserModel = .init(apiService: mock)

        await #expect(throws: NetworkError.self) {
            try await model.deleteAccount(modelContext: context)
        }

        #expect(try context.fetch(FetchDescriptor<User>()).count == 2)
    }
}
