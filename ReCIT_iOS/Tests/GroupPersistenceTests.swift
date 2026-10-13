//
//  GroupPersistenceTests.swift
//  ReCIT_iOSTests
//
//  My groups in the store (issue 0103): there before any answer from the network, updated in
//  place by a sync, gone once the server stops naming them — and a group from a search never
//  touched. See PRD 0019 and ADR 0001.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("Groups in the store")
struct GroupPersistenceTests {

    @Test("A relaunch reads my groups from the store, before any answer and without a network")
    func relaunchReadsTheStore() async throws {
        let defaults: UserDefaults = GroupFixture.makeDefaults()
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub(
            "/api/groups",
            json: GroupFixture.groupsJSON([
                GroupFixture.groupJSON(id: "mine", name: "Club", admins: ["me"]),
                GroupFixture.groupJSON(id: "invite", name: "Polars", invited: ["me"])
            ])
        )
        try await GroupFixture.makeModel(mock, defaults: defaults).syncMyGroups(myUserId: "me", modelContext: context)

        let offline: MockAPIService = .init()
        offline.stub("/api", error: URLError(.notConnectedToInternet))
        let relaunched: GroupModel = GroupFixture.makeModel(offline, defaults: defaults)

        let groups: MyGroups = try GroupFixture.myGroups(relaunched, context)
        #expect(relaunched.myUserId == "me")
        #expect(groups.mine.map(\.id) == ["mine"])
        #expect(groups.invitations.map(\.id) == ["invite"])
        #expect(offline.recordedRequests.isEmpty)
    }

    @Test("A sync updates a group in place: the stored object keeps its identity")
    func upsertKeepsIdentity() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let first: MockAPIService = .init()
        first.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        first.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", name: "Club", members: ["me"])]))
        try await GroupFixture.makeModel(first).syncMyGroups(myUserId: "me", modelContext: context)
        let held: StoredGroup = try #require(try GroupFixture.stored(context).first)
        let identity: PersistentIdentifier = held.persistentModelID

        let second: MockAPIService = .init()
        second.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        second.stub(
            "/api/groups",
            json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", name: "Le Club", admins: ["me"], members: ["m"])])
        )
        try await GroupFixture.makeModel(second).syncMyGroups(myUserId: "me", modelContext: context)

        let stored: [StoredGroup] = try GroupFixture.stored(context)
        #expect(stored.count == 1)
        #expect(stored.first?.persistentModelID == identity)
        // The object a screen was holding is the one that moved.
        #expect(held.isStillInTheStore)
        #expect(held.name == "Le Club")
        #expect(held.readerGroup.role(of: "me") == .admin)
        #expect(held.readerGroup.memberIds == ["me", "m"])
    }

    @Test("A group I left, or whose invitation was withdrawn, is gone at the next sync; a group from a search is not touched")
    func deletionScope() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/by-id", json: #"{"group":"# + GroupFixture.groupJSON(id: "found", name: "Found") + #","users":[]}"#)
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub(
            "/api/groups",
            json: GroupFixture.groupsJSON([
                GroupFixture.groupJSON(id: "kept", name: "Kept", members: ["me"]),
                GroupFixture.groupJSON(id: "left", name: "Left", members: ["me"]),
                GroupFixture.groupJSON(id: "withdrawn", name: "Withdrawn", invited: ["me"])
            ])
        )
        let model: GroupModel = GroupFixture.makeModel(mock)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)
        try await model.fetchGroup(id: "found", modelContext: context)
        #expect(Set(try GroupFixture.stored(context).map(\._id)) == ["kept", "left", "withdrawn"])

        // The next answer: I left one group, and the other's invitation was withdrawn.
        mock.restub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "kept", name: "Kept", members: ["me"])]))
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        #expect(try GroupFixture.stored(context).map(\._id) == ["kept"])
        #expect(try GroupFixture.myGroups(model, context).invitations.isEmpty)
        #expect(model.group(id: "found", in: context)?.name == "Found")
        // A screen still open on a group the sync dropped keeps it, as the server has it now.
        let left: ReaderGroup? = model.group(id: "left", in: context)
        #expect(left?.name == "Left")
        #expect(left?.role(of: "me") == nil)
        #expect(model.group(id: "withdrawn", in: context)?.role(of: "me") == nil)
    }

    @Test("A request whose read failed is kept until it can be read")
    func unreadRequestIsKept() async throws {
        let defaults: UserDefaults = GroupFixture.makeDefaults()
        let context: ModelContext = try TestStore.makeContext()
        let first: MockAPIService = .init()
        first.stub("/api/groups/request", json: #"{"ok":true}"#)
        first.stub("/api/groups/by-id", json: #"{"group":"# + GroupFixture.groupJSON(id: "far") + #","users":[]}"#)
        first.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        first.stub("/api/groups", json: #"{"groups":[]}"#)
        let model: GroupModel = GroupFixture.makeModel(first, defaults: defaults)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)
        try await model.fetchGroup(id: "far", modelContext: context)
        model.perform(.request, on: "far", modelContext: context)
        await model.inFlightTask?.value

        let flaky: MockAPIService = .init()
        flaky.stub("/api/groups/by-id", error: URLError(.timedOut))
        flaky.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        flaky.stub("/api/groups", json: #"{"groups":[]}"#)
        let relaunched: GroupModel = GroupFixture.makeModel(flaky, defaults: defaults)
        try await relaunched.syncMyGroups(myUserId: "me", modelContext: context)

        #expect(try GroupFixture.myGroups(relaunched, context).sentRequests.map(\.id) == ["far"])
    }

    @Test("A document without a picture or a description keeps the ones the store has")
    func sparseDocumentKeepsLocalValues() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let full: MockAPIService = .init()
        full.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        full.stub(
            "/api/groups",
            json: GroupFixture.groupsJSON([
                GroupFixture.groupJSON(
                    id: "g",
                    members: ["me"],
                    extra: #""picture":"/img/groups/abc","description":"On lit des polars.","slug":"club","#
                )
            ])
        )
        try await GroupFixture.makeModel(full).syncMyGroups(myUserId: "me", modelContext: context)

        let sparse: MockAPIService = .init()
        sparse.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        sparse.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", members: ["me"])]))
        try await GroupFixture.makeModel(sparse).syncMyGroups(myUserId: "me", modelContext: context)

        let stored: StoredGroup = try #require(try GroupFixture.stored(context).first)
        #expect(stored.pictureURL == "https://test.local/img/groups/abc")
        #expect(stored.groupDescription == "On lit des polars.")
        #expect(stored.slug == "club")
    }

    @Test("Merging the same document twice changes nothing the second time")
    func updateIsIdempotent() throws {
        let dto: GroupDTO = try JSONDecoder().decode(
            GroupDTO.self,
            from: Data(GroupFixture.groupJSON(id: "g", members: ["me"], extra: #""_rev":"3-a","description":"d","#).utf8)
        )
        let stored: StoredGroup = .init(dto: dto, pictureURL: "https://test.local/img/groups/abc")
        let once: ReaderGroup = stored.readerGroup

        stored.update(from: dto, pictureURL: "https://test.local/img/groups/abc")
        stored.update(from: dto, pictureURL: nil)

        #expect(stored.readerGroup == once)
        #expect(stored._rev == "3-a")
    }

    @Test("A stored group reads out as the value it was made from")
    func roundTrip() {
        let group: ReaderGroup = .init(
            id: "g",
            name: "Club",
            slug: "club",
            description: "On lit.",
            pictureURL: "https://test.local/img/groups/abc",
            searchable: false,
            open: true,
            admins: [.init(user: "a", invitor: nil, timestamp: 1)],
            members: [.init(user: "m", invitor: "a", timestamp: 2)],
            invited: [.init(user: "i", invitor: "m", timestamp: 3)],
            declined: [.init(user: "d", invitor: "a", timestamp: 4)],
            requested: [.init(user: "r", invitor: nil, timestamp: 5)]
        )

        #expect(StoredGroup(group: group).readerGroup == group)
    }
}
