//
//  UserModelEmailInvitationTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite
struct UserModelEmailInvitationTests {
    private static let endpoint: String = "/api/invitations/by-emails"

    private static func body(_ mock: MockAPIService) throws -> [String: Any] {
        let data: Data = try #require(mock.sentPayloads.first)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test
    func `posts the addresses read from the field to the canonical path, without my own`() async throws {
        let mock: MockAPIService = .init()
        mock.stub(Self.endpoint, json: #"{"users":[],"emails":["a@b.fr","c@d.fr"]}"#)
        let model: UserModel = .init(apiService: mock)
        let list: EmailInvitationList = .init("A@b.fr, a@b.fr; c@d.fr Moi@example.org", excluding: "moi@example.org")

        _ = try await model.sendEmailInvitations(list, message: "", groupId: nil)

        #expect(mock.recordedRequests.map(\.endpoint) == [Self.endpoint])
        #expect(mock.recordedRequests.map(\.method) == ["POST"])
        let body: [String: Any] = try Self.body(mock)
        #expect(body["emails"] as? [String] == ["a@b.fr", "c@d.fr"])
        #expect(body["message"] == nil)
        #expect(body["group"] == nil)
    }

    @Test
    func `sends the message when there is one, and the group when inviting to it`() async throws {
        let mock: MockAPIService = .init()
        mock.stub(Self.endpoint, json: #"{"users":[],"emails":["a@b.fr"]}"#)
        let model: UserModel = .init(apiService: mock)

        _ = try await model.sendEmailInvitations(
            .init("a@b.fr", excluding: nil),
            message: "Viens voir mes livres",
            groupId: "group-1"
        )

        let body: [String: Any] = try Self.body(mock)
        #expect(body["message"] as? String == "Viens voir mes livres")
        #expect(body["group"] as? String == "group-1")
    }

    @Test
    func `leaves a blank message out`() async throws {
        let mock: MockAPIService = .init()
        mock.stub(Self.endpoint, json: #"{"users":[],"emails":["a@b.fr"]}"#)
        let model: UserModel = .init(apiService: mock)

        _ = try await model.sendEmailInvitations(.init("a@b.fr", excluding: nil), message: " \n ", groupId: nil)

        #expect(try Self.body(mock)["message"] == nil)
    }

    @Test
    func `reads who was mailed and who already had an account`() async throws {
        let mock: MockAPIService = .init()
        mock.stub(
            Self.endpoint,
            json: #"{"users":[{"_id":"user-2","username":"camille.b","email":"c@d.fr"}],"emails":["a@b.fr"]}"#
        )
        let model: UserModel = .init(apiService: mock)

        let outcome: EmailInvitationOutcome = try await model.sendEmailInvitations(
            .init("a@b.fr, c@d.fr", excluding: nil),
            message: "",
            groupId: "group-1"
        )

        #expect(outcome == .init(invitedAddresses: ["a@b.fr"], existingUsernames: ["camille.b"], isForGroup: true))
        #expect(outcome.hasExistingAccounts)
    }

    @Test
    func `reads an answer missing its lists as nobody`() async throws {
        let mock: MockAPIService = .init()
        mock.stub(Self.endpoint, json: "{}")
        let model: UserModel = .init(apiService: mock)

        let outcome: EmailInvitationOutcome = try await model.sendEmailInvitations(
            .init("a@b.fr", excluding: nil),
            message: "",
            groupId: nil
        )

        #expect(outcome == .init(invitedAddresses: [], existingUsernames: [], isForGroup: false))
    }

    @Test
    func `a 429 throws the quota`() async {
        let mock: MockAPIService = .init()
        mock.stub(Self.endpoint, error: NetworkError.badStatus(code: 429, message: nil))
        let model: UserModel = .init(apiService: mock)

        do throws(EmailInvitationFailure) {
            _ = try await model.sendEmailInvitations(.init("a@b.fr", excluding: nil), message: "", groupId: nil)
            Issue.record("Expected the quota to be thrown")
        } catch .rateLimited {
            return
        } catch {
            Issue.record("Expected .rateLimited, got \(error)")
        }
    }
}
