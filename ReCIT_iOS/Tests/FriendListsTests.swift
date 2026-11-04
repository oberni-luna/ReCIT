//
//  FriendListsTests.swift
//  ReCIT_iOSTests
//
//  A friend's lists live in the same store as mine, told apart by `EntityList.creatorId`. The
//  sync of one reader's lists may only prune that reader's, the app offers mine alone wherever it
//  writes, and a friend's lists leave with the relation. See PRD 0031.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("A friend's lists", .serialized)
struct FriendListsTests {

    private func listsJSON(_ lists: [(id: String, creator: String?)]) -> String {
        let docs: [String] = lists.map { list in
            let creator: String = list.creator.map { #""creator": "\#($0)","# } ?? ""
            return """
            {
              "_id": "\(list.id)", "_rev": "1-abc", "name": "\(list.id)", "description": "",
              \(creator)
              "created": 1700000000, "updated": null, "visibility": ["friends"],
              "type": "work", "elements": []
            }
            """
        }
        return #"{ "total": \#(lists.count), "lists": [\#(docs.joined(separator: ","))] }"#
    }

    private func storedIDs(_ context: ModelContext) throws -> Set<String> {
        .init(try context.fetch(FetchDescriptor<EntityList>()).map(\._id))
    }

    @Test("A friend's sync stores their lists under their id")
    func friendSyncStampsTheCreator() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "theirs-1", creator: "user-2"), (id: "theirs-2", creator: nil)]))
        let friend: User = Fixture.user(id: "user-2", username: "friend")
        context.insert(friend)

        try await ListModel(apiService: mock).syncFriendLists(of: friend, modelContext: context)

        let lists: [EntityList] = try context.fetch(FetchDescriptor<EntityList>())
        #expect(lists.count == 2)
        // The answer that leaves `creator` out is still theirs: it is what was asked for.
        #expect(lists.allSatisfy { $0.creatorId == "user-2" })
    }

    @Test("A friend's sync leaves my lists alone, stamped or not")
    func friendSyncKeepsMine() async throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(EntityList.mock(id: "mine-1", creatorId: "user-1"))
        context.insert(EntityList.mock(id: "mine-legacy", creatorId: nil))
        context.insert(EntityList.mock(id: "theirs-gone", creatorId: "user-2"))
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "theirs-1", creator: "user-2")]))
        let friend: User = Fixture.user(id: "user-2", username: "friend")
        context.insert(friend)

        try await ListModel(apiService: mock).syncFriendLists(of: friend, modelContext: context)

        // Theirs that the server no longer lists go; mine are none of this sync's business.
        #expect(try storedIDs(context) == ["mine-1", "mine-legacy", "theirs-1"])
    }

    @Test("My sync prunes my unstamped lists and leaves a friend's alone")
    func mySyncClaimsUnstampedLists() async throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(EntityList.mock(id: "mine-kept", creatorId: nil))
        context.insert(EntityList.mock(id: "mine-gone", creatorId: nil))
        context.insert(EntityList.mock(id: "theirs-1", creatorId: "user-2"))
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "mine-kept", creator: "user-1")]))
        let me: User = Fixture.user(id: "user-1", username: "me")
        context.insert(me)

        try await ListModel(apiService: mock).syncLists(forUser: me, modelContext: context)

        #expect(try storedIDs(context) == ["mine-kept", "theirs-1"])
        let kept: EntityList? = try context.fetch(FetchDescriptor<EntityList>()).first { $0._id == "mine-kept" }
        #expect(kept?.creatorId == "user-1")
    }

    @Test("Mine are the unstamped lists and the ones I made, never a friend's")
    func isCreatedByMe() {
        #expect(EntityList.mock(id: "a", creatorId: nil).isCreated(byMe: "user-1"))
        #expect(EntityList.mock(id: "b", creatorId: "user-1").isCreated(byMe: "user-1"))
        #expect(EntityList.mock(id: "c", creatorId: "user-2").isCreated(byMe: "user-1") == false)
        // Without knowing who I am, only the unstamped lists can be mine.
        #expect(EntityList.mock(id: "d", creatorId: "user-1").isCreated(byMe: nil) == false)
        #expect(EntityList.mock(id: "e", creatorId: nil).isCreated(byMe: nil))
    }

    @Test("Unfriending takes their lists, not mine")
    func unfriendPrunesTheirLists() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/relations", json: #"{ "ok": true }"#)
        let model: UserModel = .init(apiService: mock)

        let friend: User = Fixture.user(id: "user-2", username: "friend")
        friend.relation = .friend
        context.insert(friend)
        context.insert(EntityList.mock(id: "mine-1", creatorId: "user-1"))
        context.insert(EntityList.mock(id: "mine-legacy", creatorId: nil))
        context.insert(EntityList.mock(id: "theirs-1", creatorId: "user-2"))
        try context.save()

        model.unfriend(friend, modelContext: context)
        await model.inFlightTask?.value

        #expect(try storedIDs(context) == ["mine-1", "mine-legacy"])
    }
}
