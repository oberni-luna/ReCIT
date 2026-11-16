//
//  LocalSearchMatchesFriendsTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct LocalSearchMatchesFriendsTests {
    private func stored(_ users: [User]) throws -> [User] {
        let context: ModelContext = try TestStore.makeContext()
        users.forEach(context.insert)
        return users
    }

    @Test
    func `keeps friends only, never a pending invitation or another reader`() throws {
        let users: [User] = try stored([
            Fixture.user(id: "friend", username: "bella", relation: .friend),
            Fixture.user(id: "sent", username: "belle", relation: .requestSent),
            Fixture.user(id: "received", username: "belinda", relation: .requestReceived),
            Fixture.user(id: "stranger", username: "isabel", relation: .none)
        ])

        let matches: LocalSearchMatches<User> = .friends(in: users, matching: "bel")

        #expect(matches.items.map(\._id) == ["friend"])
        #expect(matches.totalCount == 1)
    }

    @Test
    func `matches the username whatever its case and accents`() throws {
        let users: [User] = try stored([
            Fixture.user(id: "helene", username: "Hélène", relation: .friend),
            Fixture.user(id: "marc", username: "marc", relation: .friend)
        ])

        let matches: LocalSearchMatches<User> = .friends(in: users, matching: "HELE")

        #expect(matches.items.map(\._id) == ["helene"])
    }

    @Test
    func `sorts friends by username`() throws {
        let users: [User] = try stored([
            Fixture.user(id: "zoe", username: "Zoé", relation: .friend),
            Fixture.user(id: "anna", username: "anna", relation: .friend),
            Fixture.user(id: "emile", username: "Émile", relation: .friend)
        ])

        let matches: LocalSearchMatches<User> = .friends(in: users, matching: "e")

        #expect(matches.items.map(\._id) == ["emile", "zoe"])
    }

    @Test
    func `shows three of four matching friends and is capped`() throws {
        let users: [User] = try stored([
            Fixture.user(id: "d", username: "dabel", relation: .friend),
            Fixture.user(id: "a", username: "abel", relation: .friend),
            Fixture.user(id: "c", username: "cabel", relation: .friend),
            Fixture.user(id: "b", username: "babel", relation: .friend)
        ])

        let matches: LocalSearchMatches<User> = .friends(in: users, matching: "bel")
        let everyMatch: LocalSearchMatches<User> = .friends(
            in: users,
            matching: "bel",
            limit: InventorySearchRanking.noLimit
        )

        #expect(matches.items.map(\._id) == ["a", "b", "c"])
        #expect(matches.totalCount == 4)
        #expect(matches.isCapped)
        #expect(everyMatch.items.map(\._id) == ["a", "b", "c", "d"])
    }

    @Test
    func `shows exactly three matching friends without being capped`() throws {
        let users: [User] = try stored([
            Fixture.user(id: "a", username: "abel", relation: .friend),
            Fixture.user(id: "b", username: "babel", relation: .friend),
            Fixture.user(id: "c", username: "cabel", relation: .friend)
        ])

        let matches: LocalSearchMatches<User> = .friends(in: users, matching: "bel")

        #expect(matches.items.count == 3)
        #expect(!matches.isCapped)
    }

    @Test
    func `matches no friend for a blank query`() throws {
        let users: [User] = try stored([Fixture.user(id: "a", username: "abel", relation: .friend)])

        let matches: LocalSearchMatches<User> = .friends(in: users, matching: " ")

        #expect(matches.items.isEmpty)
        #expect(matches.totalCount == 0)
    }

    @Test
    func `drops a friend gone from the store`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let kept: User = Fixture.user(id: "kept", username: "abel", relation: .friend)
        let deleted: User = Fixture.user(id: "deleted", username: "babel", relation: .friend)
        context.insert(kept)
        context.insert(deleted)
        try context.save()

        context.delete(deleted)
        try context.save()

        let matches: LocalSearchMatches<User> = .friends(in: [deleted, kept], matching: "bel")

        #expect(matches.items.count == 1)
        #expect(matches.items.first === kept)
    }
}
