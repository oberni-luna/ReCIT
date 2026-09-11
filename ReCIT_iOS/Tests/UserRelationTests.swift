//
//  UserRelationTests.swift
//  ReCIT_iOSTests
//
//  The four lists `GET /api/relations` answers with, and the one rule that matters between
//  them: which one wins when the same reader appears twice.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@Suite("UserRelation.byUserID")
struct UserRelationTests {

    private func network(
        friends: [String] = [],
        userRequested: [String] = [],
        otherRequested: [String] = [],
        network: [String] = []
    ) -> UserNetworkDTO {
        .init(
            friends: friends,
            userRequested: userRequested,
            otherRequested: otherRequested,
            network: network
        )
    }

    @Test("Each list maps to the state it means")
    func mapsEachList() {
        let states: [String: UserRelation] = UserRelation.byUserID(
            from: network(friends: ["a"], userRequested: ["b"], otherRequested: ["c"])
        )

        #expect(states["a"] == .friend)
        #expect(states["b"] == .requestSent)
        #expect(states["c"] == .requestReceived)
    }

    @Test("A friend stays a friend, whatever stale request sits beside them")
    func friendshipWins() {
        let states: [String: UserRelation] = UserRelation.byUserID(
            from: network(friends: ["a"], userRequested: ["a"], otherRequested: ["a"])
        )

        #expect(states["a"] == .friend)
    }

    @Test("Being in the network is not being a friend")
    func networkIsNotFriendship() {
        let states: [String: UserRelation] = UserRelation.byUserID(
            from: network(friends: ["a"], network: ["a", "group-mate"])
        )

        #expect(states["group-mate"] == nil)
        #expect(states.count == 1)
    }
}

@MainActor
@Suite("UserModel.syncRelations", .serialized)
struct UserModelRelationsTests {

    private func context(with users: [User]) throws -> ModelContext {
        let context: ModelContext = try TestStore.makeContext()
        for user in users {
            context.insert(user)
        }
        try context.save()
        return context
    }

    private func model(_ context: ModelContext, json: String) throws -> (UserModel, MockAPIService) {
        let mock: MockAPIService = .init()
        mock.stub("/api/relations", json: json)
        mock.stub("/api/users/by-ids", json: #"{"users":{}}"#)
        let model: UserModel = .init(apiService: mock)
        model.myUser = try context.fetch(FetchDescriptor<User>()).first { $0._id == "me" }
        return (model, mock)
    }

    @Test("The four lists land on the users they name")
    func writesTheFourStates() async throws {
        let context: ModelContext = try context(with: [
            Fixture.user(id: "me", username: "me"),
            Fixture.user(id: "a", username: "Camille"),
            Fixture.user(id: "b", username: "Ariane"),
            Fixture.user(id: "c", username: "Rémi")
        ])
        let (model, mock): (UserModel, MockAPIService) = try model(
            context,
            json: #"{"friends":["a"],"userRequested":["b"],"otherRequested":["c"],"network":["a"]}"#
        )

        try await model.syncRelations(modelContext: context)

        let byID: [String: User] = .init(
            try context.fetch(FetchDescriptor<User>()).map { ($0._id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        #expect(byID["a"]?.relation == .friend)
        #expect(byID["b"]?.relation == .requestSent)
        #expect(byID["c"]?.relation == .requestReceived)
        #expect(mock.recordedRequests.first?.endpoint == "/api/relations")
    }

    @Test("A reader the answer no longer names falls back to none")
    func droppedRelationsFallBack() async throws {
        let friend: User = Fixture.user(id: "a", username: "Camille")
        friend.relation = .friend
        let context: ModelContext = try context(with: [Fixture.user(id: "me", username: "me"), friend])
        let (model, _): (UserModel, MockAPIService) = try model(
            context,
            json: #"{"friends":[],"userRequested":[],"otherRequested":[],"network":[]}"#
        )

        try await model.syncRelations(modelContext: context)

        #expect(friend.relation == .none)
        #expect(model.friends(modelContext: context).isEmpty)
    }

    @Test("Friends are the only readers the Profil and the inventory sync care about")
    func friendsAreFiltered() async throws {
        let context: ModelContext = try context(with: [
            Fixture.user(id: "me", username: "me"),
            Fixture.user(id: "a", username: "Camille"),
            Fixture.user(id: "stranger", username: "inconnu")
        ])
        let (model, _): (UserModel, MockAPIService) = try model(
            context,
            json: #"{"friends":["a"],"userRequested":[],"otherRequested":[],"network":["a","stranger"]}"#
        )

        try await model.syncRelations(modelContext: context)

        #expect(model.friends(modelContext: context).map(\._id) == ["a"])
        #expect(model.getAllOtherUsers(modelContext: context).count == 2)
    }
}

@MainActor
@Suite("UserModel relation writes", .serialized)
struct UserModelRelationWritesTests {

    private func makeStore() throws -> (ModelContext, User, User) {
        let context: ModelContext = try TestStore.makeContext()
        let me: User = Fixture.user(id: "me", username: "me")
        let other: User = Fixture.user(id: "other", username: "Camille")
        context.insert(me)
        context.insert(other)
        try context.save()
        return (context, me, other)
    }

    @Test("Asking flips the state before the server answers, and posts the documented body")
    func requestIsOptimistic() async throws {
        let (context, me, other): (ModelContext, User, User) = try makeStore()
        let mock: MockAPIService = .init()
        mock.stub("/api/relations/request", json: #"{"ok":true}"#)
        let model: UserModel = .init(apiService: mock)
        model.myUser = me

        model.requestRelation(with: other, modelContext: context)
        #expect(other.relation == .requestSent)

        await model.inFlightTask?.value
        #expect(other.relation == .requestSent)
        #expect(mock.recordedRequests.last?.endpoint == "/api/relations/request")
        #expect(mock.recordedRequests.last?.method == "POST")
    }

    @Test("A refused request puts the previous state back, and says so")
    func requestRevertsOnFailure() async throws {
        let (context, me, other): (ModelContext, User, User) = try makeStore()
        let mock: MockAPIService = .init()
        mock.stub("/api/relations/request", error: NetworkError.badResponse)
        let reporter: AppErrorReporter = .init()
        let model: UserModel = .init(apiService: mock, errorReporter: reporter)
        model.myUser = me

        model.requestRelation(with: other, modelContext: context)
        await model.inFlightTask?.value

        #expect(other.relation == .none)
        #expect(reporter.lastFailure != nil)
    }

    @Test("Cancelling takes the request back to nothing, on /cancel")
    func cancelUndoesTheRequest() async throws {
        let (context, me, other): (ModelContext, User, User) = try makeStore()
        other.relation = .requestSent
        let mock: MockAPIService = .init()
        mock.stub("/api/relations/cancel", json: #"{"ok":true}"#)
        let model: UserModel = .init(apiService: mock)
        model.myUser = me

        model.cancelRelation(with: other, modelContext: context)
        #expect(other.relation == .none)

        await model.inFlightTask?.value
        #expect(mock.recordedRequests.last?.endpoint == "/api/relations/cancel")
    }

    @Test("A refused cancellation leaves the request standing")
    func cancelRevertsOnFailure() async throws {
        let (context, me, other): (ModelContext, User, User) = try makeStore()
        other.relation = .requestSent
        let mock: MockAPIService = .init()
        mock.stub("/api/relations/cancel", error: NetworkError.badResponse)
        let model: UserModel = .init(apiService: mock, errorReporter: .init())
        model.myUser = me

        model.cancelRelation(with: other, modelContext: context)
        await model.inFlightTask?.value

        #expect(other.relation == .requestSent)
    }
}
