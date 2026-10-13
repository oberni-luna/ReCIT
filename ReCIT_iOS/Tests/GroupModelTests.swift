//
//  GroupModelTests.swift
//  ReCIT_iOSTests
//
//  The groups as the Réseau tab sees them: what a sync leaves in the store, where a gesture is
//  sent, what a refusal puts back, and the requests remembered across launches.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("GroupModel")
struct GroupModelTests {

    @Test("A sync stores the groups by role, and the people they name")
    func sync() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON(["admin", "friend"]))
        mock.stub(
            "/api/groups",
            json: GroupFixture.groupsJSON([
                GroupFixture.groupJSON(id: "mine", admins: ["me"], requested: ["friend"]),
                GroupFixture.groupJSON(id: "invite", invited: ["me"])
            ])
        )
        let model: GroupModel = GroupFixture.makeModel(mock)

        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        let groups: MyGroups = try GroupFixture.myGroups(model, context)
        #expect(Set(try GroupFixture.stored(context).map(\._id)) == ["mine", "invite"])
        #expect(groups.mine.map(\.id) == ["mine"])
        #expect(groups.invitations.map(\.id) == ["invite"])
        #expect(groups.requestsToReview == 1)
        #expect(groups.pendingCount == 2)
        let users: [User] = try context.fetch(FetchDescriptor<User>())
        #expect(Set(users.map(\._id)) == ["admin", "friend"])
    }

    @Test("A gesture is shown at once, and sent as a PUT on its own path")
    func optimisticGesture() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/accept", json: #"{"ok":true}"#)
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", invited: ["me"])]))
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.accept, on: "g", modelContext: context)
        #expect(try GroupFixture.myGroups(model, context).mine.map(\.id) == ["g"])

        await model.inFlightTask?.value
        #expect(reporter.lastFailure == nil)
        #expect(try GroupFixture.stored(context).first?.readerGroup.role(of: "me") == .member)
        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/groups/accept" && $0.method == "PUT" })
    }

    @Test("A refused acceptance puts the invitation back in the store")
    func acceptReverts() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/accept", error: NetworkError.badStatus(code: 500, message: nil))
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", invited: ["me"])]))
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.accept, on: "g", modelContext: context)
        #expect(try GroupFixture.myGroups(model, context).mine.map(\.id) == ["g"])

        await model.inFlightTask?.value
        let groups: MyGroups = try GroupFixture.myGroups(model, context)
        #expect(groups.mine.isEmpty)
        #expect(groups.invitations.map(\.id) == ["g"])
        #expect(try GroupFixture.stored(context).first?.readerGroup.role(of: "me") == .invited)
        #expect(reporter.lastFailure != nil)
    }

    @Test("A refused gesture puts the group back, and says so")
    func revert() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/leave", error: NetworkError.badStatus(code: 403, message: "nope"))
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", members: ["me"])]))
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.leave, on: "g", modelContext: context)
        #expect(try GroupFixture.myGroups(model, context).mine.isEmpty)

        await model.inFlightTask?.value
        #expect(try GroupFixture.myGroups(model, context).mine.map(\.id) == ["g"])
        #expect(reporter.lastFailure != nil)
    }

    @Test("A refused refusal puts the invitation back")
    func declineReverts() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/decline", error: NetworkError.badStatus(code: 500, message: nil))
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", invited: ["me"])]))
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.decline, on: "g", modelContext: context)
        #expect(try GroupFixture.myGroups(model, context).invitations.isEmpty)

        await model.inFlightTask?.value
        #expect(try GroupFixture.myGroups(model, context).invitations.map(\.id) == ["g"])
        #expect(reporter.lastFailure != nil)
    }

    @Test("An invitation is shown at once, and taken back if refused")
    func inviteReverts() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/invite", error: NetworkError.badStatus(code: 400, message: nil))
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", members: ["me"])]))
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.invite, on: "g", target: "friend", modelContext: context)
        #expect(try GroupFixture.stored(context).first?.readerGroup.role(of: "friend") == .invited)

        await model.inFlightTask?.value
        #expect(try GroupFixture.stored(context).first?.readerGroup.role(of: "friend") == nil)
        #expect(reporter.lastFailure != nil)
        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/groups/invite" && $0.method == "PUT" })
    }

    @Test("A gesture the server would refuse is not shown, nor sent")
    func impossibleGesture() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub(
            "/api/groups",
            json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", admins: ["me"], members: ["m"])])
        )
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.leave, on: "g", modelContext: context)

        #expect(try GroupFixture.myGroups(model, context).mine.map(\.id) == ["g"])
        #expect(reporter.lastFailure != nil)
        #expect(mock.recordedRequests.contains { $0.endpoint.hasPrefix("/api/groups/leave") } == false)
    }

    @Test("A request still waiting is read back at the next sync")
    func requestSurvivesARelaunch() async throws {
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

        let second: MockAPIService = .init()
        second.stub(
            "/api/groups/by-id",
            json: #"{"group":"# + GroupFixture.groupJSON(id: "far", requested: ["me"]) + #","users":[]}"#
        )
        second.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        second.stub("/api/groups", json: #"{"groups":[]}"#)
        let relaunched: GroupModel = GroupFixture.makeModel(second, defaults: defaults)
        try await relaunched.syncMyGroups(myUserId: "me", modelContext: context)

        #expect(try GroupFixture.myGroups(relaunched, context).sentRequests.map(\.id) == ["far"])
    }

    @Test("A refused request takes the group back out of the store, into memory")
    func refusedRequestLeavesTheStore() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/request", error: NetworkError.badStatus(code: 500, message: nil))
        mock.stub("/api/groups/by-id", json: #"{"group":"# + GroupFixture.groupJSON(id: "far") + #","users":[]}"#)
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub("/api/groups", json: #"{"groups":[]}"#)
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)
        try await model.fetchGroup(id: "far", modelContext: context)
        #expect(try GroupFixture.stored(context).isEmpty)

        model.perform(.request, on: "far", modelContext: context)
        #expect(try GroupFixture.myGroups(model, context).sentRequests.map(\.id) == ["far"])

        await model.inFlightTask?.value
        #expect(try GroupFixture.stored(context).isEmpty)
        #expect(model.group(id: "far", in: context)?.role(of: "me") == nil)
        #expect(reporter.lastFailure != nil)
    }

    @Test("Signing out forgets who the groups were for, and the wipe takes them")
    func reset() async throws {
        let defaults: UserDefaults = GroupFixture.makeDefaults()
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/users/by-ids", json: GroupFixture.usersJSON([]))
        mock.stub("/api/groups", json: GroupFixture.groupsJSON([GroupFixture.groupJSON(id: "g", members: ["me"])]))
        let model: GroupModel = GroupFixture.makeModel(mock, defaults: defaults)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.reset()
        try UserModel(apiService: MockAPIService()).wipeUserData(modelContext: context)

        #expect(model.myUserId == nil)
        #expect(try GroupFixture.stored(context).isEmpty)
        #expect(try GroupFixture.myGroups(model, context).isEmpty)
        #expect(GroupFixture.makeModel(MockAPIService(), defaults: defaults).myUserId == nil)
    }

    @Test("The search keeps the server's ranking")
    func search() async throws {
        let mock: MockAPIService = .init()
        mock.stub(
            "/api/search?types=groups",
            json: #"{"results":[{"id":"b","label":"B","_score":1},{"id":"a","label":"A","description":"d","_score":9}]}"#
        )
        let model: GroupModel = GroupFixture.makeModel(mock)

        let results: [GroupSearchResult] = try await model.searchGroups(query: "club")

        #expect(results.map(\.id) == ["a", "b"])
        #expect(results.first?.description == "d")
    }
}

@MainActor
@Suite("GroupModel · administration")
struct GroupModelAdministrationTests {

    private static let adminGroups: String = #"""
    {"groups":[{"_id":"g","name":"Club","open":false,"searchable":true,
      "admins":[{"user":"me","invitor":null,"timestamp":1}],
      "members":[{"user":"m","invitor":null,"timestamp":1}],
      "invited":[],"declined":[],"requested":[{"user":"r","invitor":null,"timestamp":1}]}]}
    """#

    private func syncedModel(_ mock: MockAPIService, reporter: AppErrorReporter? = nil) async throws -> (GroupModel, ModelContext) {
        let context: ModelContext = try TestStore.makeContext()
        mock.stub("/api/users/by-ids", json: #"{"users":{}}"#)
        mock.stub("/api/groups", json: Self.adminGroups)
        let model: GroupModel = GroupFixture.makeModel(mock, reporter: reporter)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)
        return (model, context)
    }

    @Test("Accepting a request makes a member, and the gesture names them")
    func acceptRequest() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/accept-request", json: #"{"ok":true}"#)
        let (model, context) = try await syncedModel(mock)

        model.perform(.acceptRequest, on: "g", target: "r", modelContext: context)
        #expect(model.group(id: "g", in: context)?.role(of: "r") == .member)
        #expect(try GroupFixture.myGroups(model, context).requestsToReview == 0)

        await model.inFlightTask?.value
        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/groups/accept-request" })
    }

    @Test("A setting is shown at once, and put back if refused")
    func settingReverts() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/update-settings", error: NetworkError.badStatus(code: 400, message: "spam"))
        let reporter: AppErrorReporter = .init()
        let (model, context) = try await syncedModel(mock, reporter: reporter)

        model.update(.name("Polars"), on: "g", modelContext: context)
        #expect(try GroupFixture.stored(context).first?.name == "Polars")

        await model.inFlightTask?.value
        #expect(try GroupFixture.stored(context).first?.name == "Club")
        #expect(reporter.lastFailure != nil)
    }

    @Test("A created group is one of mine, as its admin, and in the store")
    func create() async throws {
        let defaults: UserDefaults = GroupFixture.makeDefaults()
        let context: ModelContext = try TestStore.makeContext()
        let sync: MockAPIService = .init()
        sync.stub("/api/groups", json: #"{"groups":[]}"#)
        try await GroupFixture.makeModel(sync, defaults: defaults).syncMyGroups(myUserId: "me", modelContext: context)

        // A later launch: who I am comes back from the device, not from a sync.
        let mock: MockAPIService = .init()
        mock.stub(
            "/api/groups",
            json: #"{"_id":"new","name":"Polars","slug":"polars","open":true,"searchable":false,"admins":[{"user":"me","invitor":null,"timestamp":1}],"members":[],"invited":[],"declined":[],"requested":[]}"#
        )
        let model: GroupModel = GroupFixture.makeModel(mock, defaults: defaults)

        let group: ReaderGroup = try await model.createGroup(
            name: " Polars ",
            description: "",
            searchable: false,
            open: true,
            modelContext: context
        )

        #expect(group.id == "new")
        #expect(group.open)
        #expect(try GroupFixture.stored(context).map(\._id) == ["new"])
        #expect(try GroupFixture.myGroups(model, context).mine.map(\.id) == ["new"])
        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/groups" && $0.method == "POST" })
    }
}
