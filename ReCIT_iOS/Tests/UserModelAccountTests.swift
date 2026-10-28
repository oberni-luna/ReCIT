//
//  UserModelAccountTests.swift
//  ReCIT_iOSTests
//
//  The owner's settings: switches that write themselves and go back alone if refused, and the
//  address and password, written server first.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("UserModel account", .serialized)
struct UserModelAccountTests {

    private func model(_ mock: MockAPIService) throws -> (UserModel, ModelContext) {
        let context: ModelContext = try TestStore.makeContext()
        let me: User = Fixture.user(id: "user-1", username: "OlivierB")
        context.insert(me)
        let model: UserModel = .init(apiService: mock, userUpdateInterval: .zero)
        model.myUser = me
        model.account = .init(
            email: "o@example.org",
            isEmailValidated: true,
            language: "fr",
            isFediversable: false,
            anonymizesContributions: true,
            summaryPeriodicity: 20,
            notifications: [:]
        )
        return (model, context)
    }

    private func body(_ mock: MockAPIService, at index: Int) -> String {
        String(decoding: mock.sentPayloads[index], as: UTF8.self)
    }

    @Test("A switch changes at once and sends its attribute")
    func optimisticSwitch() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        let (model, context) = try model(mock)

        model.setFediversable(true, modelContext: context)
        #expect(model.account?.isFediversable == true)
        await model.inFlightAccountTask?.value

        #expect(body(mock, at: 0).contains(#""attribute":"fediversable""#))
        #expect(body(mock, at: 0).contains(#""value":true"#))
        #expect(model.account?.isFediversable == true)
    }

    @Test("A refused switch goes back, and only that one")
    func refusalRevertsOnlyItself() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        mock.onSend = { index in
            if index == 0 { throw NetworkError.badStatus(code: 429, message: nil) }
        }
        let reporter: AppErrorReporter = .init()
        let (model, context) = try model(mock)
        model.errorReporter = reporter

        model.setNotification(.groupInvite, to: false, modelContext: context)
        let first: Task<Void, Never>? = model.inFlightAccountTask
        model.setSummaryPeriodicity(7, modelContext: context)
        let second: Task<Void, Never>? = model.inFlightAccountTask
        await first?.value
        await second?.value

        #expect(model.account?.isEnabled(.groupInvite) == true)
        #expect(model.account?.summaryPeriodicity == 7)
        #expect(reporter.lastFailure != nil)
    }

    @Test("Setting a value the account already has sends nothing")
    func sameValueSendsNothing() throws {
        let mock: MockAPIService = .init()
        let (model, context) = try model(mock)

        model.setLanguage("fr", modelContext: context)
        #expect(mock.sentPayloads.isEmpty)
    }

    @Test("A new address is held unconfirmed")
    func changeEmail() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/user", json: #"{"ok":true}"#)
        let (model, _) = try model(mock)

        try await model.changeEmail(to: "new@example.org")

        #expect(body(mock, at: 0).contains(#""attribute":"email""#))
        #expect(model.account?.email == "new@example.org")
        #expect(model.account?.isEmailValidated == false)
        #expect(model.myUser?.email == "new@example.org")
    }

    @Test("The password goes under the server's hyphenated names")
    func changePasswordPayload() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/auth/password", json: #"{"ok":true}"#)
        let (model, _) = try model(mock)

        try await model.changePassword(current: "old-secret", new: "new-secret")

        #expect(mock.recordedRequests.first?.method == "PUT")
        #expect(body(mock, at: 0).contains(#""old-password":"old-secret""#))
        #expect(body(mock, at: 0).contains(#""new-password":"new-secret""#))
    }

    @Test("A wrong current password is told apart")
    func wrongCurrentPassword() async throws {
        let mock: MockAPIService = .init()
        mock.stub("/api/auth/password", error: NetworkError.badStatus(code: 400, message: #"{"status_verbose":"invalid old-password"}"#))
        let (model, _) = try model(mock)

        await #expect(throws: PasswordChangeFailure.wrongCurrentPassword) {
            try await model.changePassword(current: "nope", new: "new-secret")
        }
    }

    @Test("Every language the server accepts is offered, once")
    func languages() {
        let all: [AccountLanguage] = AccountLanguage.all(locale: .init(identifier: "fr"))
        #expect(all.count == 29)
        #expect(Set(all.map(\.code)).count == 29)
        #expect(all.contains { $0.code == "fr" && $0.name == "Français" })
    }
}
