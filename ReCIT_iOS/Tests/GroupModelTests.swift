//
//  GroupModelTests.swift
//  ReCIT_iOSTests
//
//  The groups as the Réseau tab sees them: what a sync leaves in memory, where a gesture is
//  sent, what a refusal puts back, and the requests remembered across launches.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("GroupModel")
struct GroupModelTests {

    private static func groupJSON(
        id: String,
        name: String = "Club",
        open: Bool = false,
        admins: [String] = ["admin"],
        members: [String] = [],
        invited: [String] = [],
        requested: [String] = []
    ) -> String {
        func list(_ ids: [String]) -> String {
            "[" + ids.map { #"{"user":"\#($0)","invitor":null,"timestamp":1}"# }.joined(separator: ",") + "]"
        }
        return #"{"_id":"\#(id)","name":"\#(name)","open":\#(open),"searchable":true,"admins":\#(list(admins)),"members":\#(list(members)),"invited":\#(list(invited)),"declined":[],"requested":\#(list(requested))}"#
    }

    private static func usersJSON(_ ids: [String]) -> String {
        #"{"users":{"# + ids.map { #""\#($0)":{"_id":"\#($0)","username":"\#($0)"}"# }.joined(separator: ",") + "}}"
    }

    private func makeLedger() -> GroupRequestLedger {
        .init(defaults: UserDefaults(suiteName: "group-tests-\(UUID().uuidString)") ?? .standard)
    }

    @Test("A sync sorts the groups by role, and stores the people they name")
    func sync() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/users/by-ids", json: Self.usersJSON(["admin", "friend"]))
        mock.stub(
            "/api/groups",
            json: #"{"groups":["# + Self.groupJSON(id: "mine", admins: ["me"], requested: ["friend"]) + ","
                + Self.groupJSON(id: "invite", invited: ["me"]) + "]}"
        )
        let model: GroupModel = .init(apiService: mock, ledger: makeLedger())

        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        #expect(model.hasLoaded)
        #expect(model.myGroups.map(\.id) == ["mine"])
        #expect(model.invitations.map(\.id) == ["invite"])
        #expect(model.requestsToReview == 1)
        #expect(model.pendingCount == 2)
        let users: [User] = try context.fetch(FetchDescriptor<User>())
        #expect(Set(users.map(\._id)) == ["admin", "friend"])
    }

    @Test("A gesture is shown at once, and sent as a PUT on its own path")
    func optimisticGesture() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/accept", json: #"{"ok":true}"#)
        mock.stub("/api/users/by-ids", json: Self.usersJSON([]))
        mock.stub("/api/groups", json: #"{"groups":["# + Self.groupJSON(id: "g", invited: ["me"]) + #"]}"#)
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = .init(apiService: mock, errorReporter: reporter, ledger: makeLedger())
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.accept, on: "g", modelContext: context)
        #expect(model.myGroups.map(\.id) == ["g"])

        await model.inFlightTask?.value
        #expect(reporter.lastFailure == nil)
        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/groups/accept" && $0.method == "PUT" })
    }

    @Test("A refused gesture puts the group back, and says so")
    func revert() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/leave", error: NetworkError.badStatus(code: 403, message: "nope"))
        mock.stub("/api/users/by-ids", json: Self.usersJSON([]))
        mock.stub("/api/groups", json: #"{"groups":["# + Self.groupJSON(id: "g", members: ["me"]) + #"]}"#)
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = .init(apiService: mock, errorReporter: reporter, ledger: makeLedger())
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.leave, on: "g", modelContext: context)
        #expect(model.myGroups.isEmpty)

        await model.inFlightTask?.value
        #expect(model.myGroups.map(\.id) == ["g"])
        #expect(reporter.lastFailure != nil)
    }

    @Test("A gesture the server would refuse is not shown, nor sent")
    func impossibleGesture() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/users/by-ids", json: Self.usersJSON([]))
        mock.stub("/api/groups", json: #"{"groups":["# + Self.groupJSON(id: "g", admins: ["me"], members: ["m"]) + #"]}"#)
        let reporter: AppErrorReporter = .init()
        let model: GroupModel = .init(apiService: mock, errorReporter: reporter, ledger: makeLedger())
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.perform(.leave, on: "g", modelContext: context)

        #expect(model.myGroups.map(\.id) == ["g"])
        #expect(reporter.lastFailure != nil)
        #expect(mock.recordedRequests.contains { $0.endpoint.hasPrefix("/api/groups/leave") } == false)
    }

    @Test("A request still waiting is read back at the next sync")
    func requestSurvivesARelaunch() async throws {
        let ledger: GroupRequestLedger = makeLedger()
        let context: ModelContext = try TestStore.makeContext()

        let first: MockAPIService = .init()
        first.stub("/api/groups/request", json: #"{"ok":true}"#)
        first.stub("/api/groups/by-id", json: #"{"group":"# + Self.groupJSON(id: "far") + #","users":[]}"#)
        first.stub("/api/users/by-ids", json: Self.usersJSON([]))
        first.stub("/api/groups", json: #"{"groups":[]}"#)
        let model: GroupModel = .init(apiService: first, ledger: ledger)
        try await model.syncMyGroups(myUserId: "me", modelContext: context)
        try await model.fetchGroup(id: "far", modelContext: context)
        model.perform(.request, on: "far", modelContext: context)
        await model.inFlightTask?.value

        let second: MockAPIService = .init()
        second.stub(
            "/api/groups/by-id",
            json: #"{"group":"# + Self.groupJSON(id: "far", requested: ["me"]) + #","users":[]}"#
        )
        second.stub("/api/users/by-ids", json: Self.usersJSON([]))
        second.stub("/api/groups", json: #"{"groups":[]}"#)
        let relaunched: GroupModel = .init(apiService: second, ledger: ledger)
        try await relaunched.syncMyGroups(myUserId: "me", modelContext: context)

        #expect(relaunched.sentRequests.map(\.id) == ["far"])
    }

    @Test("Signing out forgets the groups")
    func reset() async throws {
        let context: ModelContext = try TestStore.makeContext()
        let mock: MockAPIService = .init()
        mock.stub("/api/users/by-ids", json: Self.usersJSON([]))
        mock.stub("/api/groups", json: #"{"groups":["# + Self.groupJSON(id: "g", members: ["me"]) + #"]}"#)
        let model: GroupModel = .init(apiService: mock, ledger: makeLedger())
        try await model.syncMyGroups(myUserId: "me", modelContext: context)

        model.reset()

        #expect(model.myGroups.isEmpty)
        #expect(model.hasLoaded == false)
    }

    @Test("The search keeps the server's ranking")
    func search() async throws {
        let mock: MockAPIService = .init()
        mock.stub(
            "/api/search?types=groups",
            json: #"{"results":[{"id":"b","label":"B","_score":1},{"id":"a","label":"A","description":"d","_score":9}]}"#
        )
        let model: GroupModel = .init(apiService: mock, ledger: makeLedger())

        let results: [GroupSearchResult] = try await model.searchGroups(query: "club")

        #expect(results.map(\.id) == ["a", "b"])
        #expect(results.first?.description == "d")
    }
}

@MainActor
@Suite("GroupModel · administration")
struct GroupModelAdministrationTests {

    private func makeLedger() -> GroupRequestLedger {
        .init(defaults: UserDefaults(suiteName: "group-admin-tests-\(UUID().uuidString)") ?? .standard)
    }

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
        let model: GroupModel = .init(apiService: mock, errorReporter: reporter, ledger: makeLedger())
        try await model.syncMyGroups(myUserId: "me", modelContext: context)
        return (model, context)
    }

    @Test("Accepting a request makes a member, and the gesture names them")
    func acceptRequest() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/groups/accept-request", json: #"{"ok":true}"#)
        let (model, context) = try await syncedModel(mock)

        model.perform(.acceptRequest, on: "g", target: "r", modelContext: context)
        #expect(model.group(id: "g")?.role(of: "r") == .member)
        #expect(model.requestsToReview == 0)

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
        #expect(model.group(id: "g")?.name == "Polars")

        await model.inFlightTask?.value
        #expect(model.group(id: "g")?.name == "Club")
        #expect(reporter.lastFailure != nil)
    }

    @Test("A created group is one of mine, as its admin")
    func create() async throws {
        let mock: MockAPIService = .init()
        mock.stub(
            "/api/groups",
            json: #"{"_id":"new","name":"Polars","slug":"polars","open":true,"searchable":false,"admins":[{"user":"me","invitor":null,"timestamp":1}],"members":[],"invited":[],"declined":[],"requested":[]}"#
        )
        let model: GroupModel = .init(apiService: mock, ledger: makeLedger())

        let group: ReaderGroup = try await model.createGroup(name: " Polars ", description: "", searchable: false, open: true)

        #expect(group.id == "new")
        #expect(group.open)
        #expect(model.group(id: "new") != nil)
        #expect(mock.recordedRequests.contains { $0.endpoint == "/api/groups" && $0.method == "POST" })
    }
}
