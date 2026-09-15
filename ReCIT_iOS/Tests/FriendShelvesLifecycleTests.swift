//
//  FriendShelvesLifecycleTests.swift
//  ReCIT_iOSTests
//
//  A friend's étagères come and go with the relation itself. `syncShelves` is what prunes
//  an owner's shelves, and it is never called again for someone who has left my network —
//  so leaving the relation has to take them. See issue 0091.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("A friend's étagères", .serialized)
struct FriendShelvesLifecycleTests {

    private func shelf(id: String, owner: String) -> Shelf {
        .init(
            _id: id,
            _rev: "1-abc",
            name: "Polars",
            slug: "polars",
            shelfDescription: "",
            ownerId: owner,
            visibility: ["friends"],
            colorHex: nil,
            created: .init(timeIntervalSince1970: 0),
            updated: nil
        )
    }

    @Test("Unfriending takes their étagères with their books")
    func unfriendPrunesTheirShelves() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/relations", json: #"{ "ok": true }"#)
        let model: UserModel = .init(apiService: mock)

        let me: User = Fixture.user(id: "user-1", username: "me")
        context.insert(me)
        model.myUser = me

        let friend: User = Fixture.user(id: "user-2", username: "friend")
        friend.relation = .friend
        context.insert(friend)

        let mine: Shelf = shelf(id: "mine-1", owner: "user-1")
        let theirs: Shelf = shelf(id: "theirs-1", owner: "user-2")
        context.insert(mine)
        context.insert(theirs)
        try context.save()

        model.unfriend(friend, modelContext: context)
        await model.inFlightTask?.value

        let ids: Set<String> = .init(try context.fetch(FetchDescriptor<Shelf>()).map(\._id))
        #expect(ids.contains("theirs-1") == false)
        // Mine are none of this relation's business.
        #expect(ids.contains("mine-1"))
    }

    @Test("A refused unfriend keeps their étagères")
    func failedUnfriendKeepsTheirShelves() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/relations", error: NetworkError.badStatus(code: 500, message: nil))
        let model: UserModel = .init(apiService: mock, errorReporter: .init())

        let friend: User = Fixture.user(id: "user-2", username: "friend")
        friend.relation = .friend
        context.insert(friend)
        context.insert(shelf(id: "theirs-1", owner: "user-2"))
        try context.save()

        model.unfriend(friend, modelContext: context)
        await model.inFlightTask?.value

        // The deletion is the reconcile half, so a server that refused never reaches it —
        // the same rule that keeps their books.
        let ids: Set<String> = .init(try context.fetch(FetchDescriptor<Shelf>()).map(\._id))
        #expect(ids.contains("theirs-1"))
        #expect(friend.relation == .friend)
    }
}
