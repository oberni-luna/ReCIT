//
//  NetworkListsTests.swift
//  ReCIT_iOSTests
//
//  « Dans mon réseau » in the Lists tab: every friend's lists synced in one request, which may
//  prune only theirs, and the two sections the tab draws from the store — mine by name, my
//  friends' the most recently changed first, a stranger's on their profile only.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Lists in my network", .serialized)
struct NetworkListsTests {

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

    private func list(id: String, name: String? = nil, creator: String?, updated: TimeInterval? = nil) -> EntityList {
        .init(
            _id: id,
            _rev: "1",
            name: name ?? id,
            explanation: "",
            created: .init(timeIntervalSince1970: 0),
            updated: updated.map { .init(timeIntervalSince1970: $0) },
            visibility: [.public],
            type: .work,
            creatorId: creator
        )
    }

    private func friend(_ id: String) -> User {
        let user: User = Fixture.user(id: id, username: id)
        user.relation = .friend
        return user
    }

    private func storedIDs(_ context: ModelContext) throws -> Set<String> {
        .init(try context.fetch(FetchDescriptor<EntityList>()).map(\._id))
    }

    @Test("One request asks for every friend's lists")
    func oneRequestForEveryFriend() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "lea-1", creator: "lea"), (id: "ines-1", creator: "ines")]))

        try await ListModel(apiService: mock).syncNetworkLists(of: [friend("lea"), friend("ines")], modelContext: context)

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
        context.insert(list(id: "mine-1", creator: "me"))
        context.insert(list(id: "mine-legacy", creator: nil))
        context.insert(list(id: "stranger-1", creator: "stranger"))
        context.insert(list(id: "lea-gone", creator: "lea"))
        try context.save()

        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "lea-1", creator: "lea")]))

        try await ListModel(apiService: mock).syncNetworkLists(of: [friend("lea"), friend("ines")], modelContext: context)

        #expect(try storedIDs(context) == ["mine-1", "mine-legacy", "stranger-1", "lea-1"])
    }

    @Test("A list that does not say whose it is is left out, or it would pass for mine")
    func unattributedListIsDropped() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/lists/by-creators", json: listsJSON([(id: "lea-1", creator: "lea"), (id: "nobody", creator: nil)]))

        try await ListModel(apiService: mock).syncNetworkLists(of: [friend("lea"), friend("ines")], modelContext: context)

        #expect(try storedIDs(context) == ["lea-1"])
    }

    @Test("Mine by name, my friends' the most recently changed first, a stranger's left out")
    func sections() {
        let lea: User = friend("lea")
        let ines: User = friend("ines")
        let lists: [EntityList] = [
            list(id: "b", name: "Livres lus", creator: "me"),
            list(id: "a", name: "Livres à lire", creator: nil),
            list(id: "lea-old", creator: "lea", updated: 100),
            list(id: "ines-new", creator: "ines", updated: 300),
            list(id: "lea-new", creator: "lea", updated: 200),
            list(id: "stranger", creator: "stranger", updated: 400),
        ]

        let sections: ListsTabSections = .init(lists: lists, myUserId: "me", friends: [lea, ines])

        #expect(sections.mine.map(\._id) == ["a", "b"])
        #expect(sections.network.map(\.id) == ["ines-new", "lea-new", "lea-old"])
        #expect(sections.network.map(\.owner._id) == ["ines", "lea", "lea"])
    }

    @Test("The search keeps the matching lists in both sections")
    func searchFiltersBothSections() {
        let lists: [EntityList] = [
            list(id: "mine-polar", name: "Polars à lire", creator: "me"),
            list(id: "mine-other", name: "Livres lus", creator: "me"),
            list(id: "lea-polar", name: "Polars nordiques", creator: "lea"),
            list(id: "lea-other", name: "Pour les enfants", creator: "lea"),
        ]

        let sections: ListsTabSections = .init(lists: lists, myUserId: "me", friends: [friend("lea")], searchText: "polar")

        #expect(sections.mine.map(\._id) == ["mine-polar"])
        #expect(sections.network.map(\.id) == ["lea-polar"])
    }
}
