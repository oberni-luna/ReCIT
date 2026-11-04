//
//  NetworkListsTests.swift
//  ReCIT_iOSTests
//
//  « Dans mon réseau » in the Lists tab: every friend's lists synced in one request, which may
//  prune only theirs. The sections the tab draws from them are `ListsTabSectionsTests`.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Lists in my network", .serialized)
struct NetworkListsTests {
    private let friends: [User] = [
        Fixture.user(id: "lea", username: "lea", relation: .friend),
        Fixture.user(id: "ines", username: "ines", relation: .friend)
    ]

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

    @Test("One request asks for every friend's lists")
    func oneRequestForEveryFriend() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "lea-1", creator: "lea"), (id: "ines-1", creator: "ines")]))

        try await ListModel(apiService: mock).syncNetworkLists(of: friends, modelContext: context)

        let endpoints: [String] = mock.recordedRequests.map(\.endpoint)
        #expect(endpoints == ["/api/lists/by-creators?users=ines|lea&with-elements=true"])
        let lists: [EntityList] = try context.fetch(FetchDescriptor<EntityList>())
        #expect(Dictionary(uniqueKeysWithValues: lists.map { ($0._id, $0.creatorId) }) == ["lea-1": "lea", "ines-1": "ines"])
    }

    @Test("No friend, no request")
    func noFriendNoRequest() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()

        try await ListModel(apiService: mock).syncNetworkLists(of: [], modelContext: context)

        #expect(mock.recordedRequests.isEmpty)
    }

    @Test("The sync prunes my friends' lists only, never mine or a stranger's")
    func pruneIsScopedToFriends() async throws {
        let context: ModelContext = try TestStore.makeContext()
        context.insert(EntityList.mock(id: "mine-1", creatorId: "me"))
        context.insert(EntityList.mock(id: "mine-legacy", creatorId: nil))
        context.insert(EntityList.mock(id: "stranger-1", creatorId: "stranger"))
        context.insert(EntityList.mock(id: "lea-gone", creatorId: "lea"))
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "lea-1", creator: "lea")]))

        try await ListModel(apiService: mock).syncNetworkLists(of: friends, modelContext: context)

        #expect(try storedIDs(context) == ["mine-1", "mine-legacy", "stranger-1", "lea-1"])
    }

    @Test("A list that does not say whose it is is left out, or it would pass for mine")
    func unattributedListIsDropped() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "lea-1", creator: "lea"), (id: "nobody", creator: nil)]))

        try await ListModel(apiService: mock).syncNetworkLists(of: friends, modelContext: context)

        #expect(try storedIDs(context) == ["lea-1"])
    }
}
