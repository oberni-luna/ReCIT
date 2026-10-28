//
//  UserModelProfileTests.swift
//  ReCIT_iOSTests
//
//  Reading the account from `GET /api/user`, and writing its public half one attribute at a time.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("UserModel profile", .serialized)
struct UserModelProfileTests {

    private struct SentUpdate: Decodable, Equatable {
        let attribute: String
    }

    private func signedIn(_ mock: MockAPIService) throws -> (UserModel, ModelContext) {
        let context: ModelContext = try TestStore.makeContext()
        let me: User = Fixture.user(id: "user-1", username: "OlivierB")
        context.insert(me)
        try context.save()
        let model: UserModel = .init(apiService: mock, userUpdateInterval: .zero)
        model.myUser = me
        return (model, context)
    }

    private func attributes(_ mock: MockAPIService) throws -> [String] {
        try mock.sentPayloads.map { try JSONDecoder().decode(SentUpdate.self, from: $0).attribute }
    }

    @Test("GET /api/user fills the bio and the owner's settings")
    func syncReadsAccount() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: """
        {"_id":"user-1","username":"OlivierB","email":"o@example.org","bio":"Lecteur lent.",
         "language":"fr","validEmail":false,"fediversable":true,"summaryPeriodicity":7,
         "settings":{"notifications":{"global":true,"group_invite":false},
                     "contributions":{"anonymize":false}}}
        """)
        let context: ModelContext = try TestStore.makeContext()
        let model: UserModel = .init(apiService: mock)

        try await model.syncMyUser(modelContext: context)

        #expect(model.myUser?.bio == "Lecteur lent.")
        let account: AccountSettings = try #require(model.account)
        #expect(account.email == "o@example.org")
        #expect(account.isEmailValidated == false)
        #expect(account.language == "fr")
        #expect(account.isFediversable)
        #expect(account.anonymizesContributions == false)
        #expect(account.summaryPeriodicity == 7)
        #expect(account.isEnabled(.groupInvite) == false)
        #expect(account.isEnabled(.friendshipRequest))
    }

    @Test("Settings an account never touched read as the server reads them")
    func absentSettingsDefaults() throws {
        let dto: UserDTO = try JSONDecoder().decode(
            UserDTO.self,
            from: Data(#"{"_id":"u","username":"x"}"#.utf8)
        )
        let account: AccountSettings = .init(userDTO: dto)
        #expect(account.anonymizesContributions)
        #expect(account.summaryPeriodicity == AccountSettings.defaultSummaryPeriodicity)
        #expect(NotificationSetting.allCases.allSatisfy { account.isEnabled($0) })
    }

    @Test("Each change is one PUT /api/user, in order, written onto the user as it lands")
    func savesEachChange() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        mock.uploadedImageUrl = "/img/users/0123456789012345678901234567890123456789"
        let (model, context) = try signedIn(mock)

        try await model.saveProfile(
            [.picture(Data([1])), .username("Olive"), .bio("Bonjour"), .position(.init(latitude: 45.57, longitude: 5.91))],
            modelContext: context
        )

        #expect(mock.recordedRequests.map(\.endpoint) == [
            "/api/images/upload?container=users", "/api/user", "/api/user", "/api/user", "/api/user",
        ])
        #expect(try attributes(mock) == ["picture", "username", "bio", "position"])
        #expect(model.myUser?.avatarURLValue == "https://test.local/img/users/0123456789012345678901234567890123456789")
        #expect(model.myUser?.username == "Olive")
        #expect(model.myUser?.bio == "Bonjour")
        #expect(model.myUser?.position == .init(latitude: 45.57, longitude: 5.91))
    }

    @Test("Taking a value away sends an explicit null")
    func removalSendsNull() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        let (model, context) = try signedIn(mock)

        try await model.saveProfile([.picture(nil), .position(nil)], modelContext: context)

        let bodies: [String] = mock.sentPayloads.map { String(decoding: $0, as: UTF8.self) }
        #expect(bodies.allSatisfy { $0.contains(#""value":null"#) })
        #expect(mock.recordedRequests.contains { $0.endpoint.contains("upload") } == false)
        #expect(model.myUser?.avatarURLValue == nil)
    }

    @Test("A refusal stops the save and says what had landed before it")
    func partialFailure() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        mock.onSend = { index in
            if index == 1 { throw NetworkError.badStatus(code: 400, message: "this username is already used") }
        }
        let (model, context) = try signedIn(mock)

        do {
            try await model.saveProfile([.bio("Bonjour"), .username("Olive"), .position(nil)], modelContext: context)
            Issue.record("expected a failure")
        } catch {
            #expect(error.refused == .username)
            #expect(error.landed == [.bio("Bonjour")])
            #expect(String(localized: error.explanation) == String(localized: "edit_profile.failure.username_taken"))
        }
        #expect(model.myUser?.bio == "Bonjour")
        #expect(model.myUser?.username == "OlivierB")
        #expect(mock.sentPayloads.count == 2)
    }
}
