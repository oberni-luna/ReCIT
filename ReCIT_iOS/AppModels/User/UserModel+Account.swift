//
//  UserModel+Account.swift
//  ReCIT_iOS
//
//  « Compte et connexion » and « Notifications par e-mail »: the owner's half of the account.
//
//  A switch or a menu writes itself, optimistic (ADR 0001): `account` changes at once, the
//  `PUT /api/user` follows in its `RequestPacer` slot, and only that one value goes back if the
//  server refuses — two switches flipped in a row are two writes, and the first failing must not
//  undo the second. The address and the password are server first: each has a screen of its own,
//  and a wrong one is something to say there, not to undo.
//

import Foundation
import SwiftData

extension UserModel {

    // MARK: - Optimistic settings

    func setLanguage(_ code: String, modelContext: ModelContext) {
        writeSetting(\.language, to: code, attribute: "language", modelContext: modelContext)
    }

    func setFediversable(_ isOn: Bool, modelContext: ModelContext) {
        writeSetting(\.isFediversable, to: isOn, attribute: "fediversable", modelContext: modelContext)
    }

    func setAnonymizesContributions(_ isOn: Bool, modelContext: ModelContext) {
        writeSetting(
            \.anonymizesContributions,
            to: isOn,
            attribute: "settings.contributions.anonymize",
            modelContext: modelContext
        )
    }

    func setSummaryPeriodicity(_ days: Int, modelContext: ModelContext) {
        writeSetting(\.summaryPeriodicity, to: days, attribute: "summaryPeriodicity", modelContext: modelContext)
    }

    func setNotification(_ setting: NotificationSetting, to isOn: Bool, modelContext: ModelContext) {
        guard let previous = account?.isEnabled(setting), previous != isOn else { return }

        inFlightAccountTask = optimistic(
            modelContext,
            apply: { self.account?.set(setting, to: isOn) },
            revert: { [weak self] in self?.account?.set(setting, to: previous) },
            request: { [weak self] in
                try await self?.updateUserAttribute(setting.attribute, value: isOn)
            }
        )
    }

    private func writeSetting<Value: Codable & Sendable & Equatable>(
        _ keyPath: WritableKeyPath<AccountSettings, Value>,
        to value: Value,
        attribute: String,
        modelContext: ModelContext
    ) {
        guard let previous = account?[keyPath: keyPath], previous != value else { return }

        inFlightAccountTask = optimistic(
            modelContext,
            apply: { self.account?[keyPath: keyPath] = value },
            revert: { [weak self] in self?.account?[keyPath: keyPath] = previous },
            request: { [weak self] in
                try await self?.updateUserAttribute(attribute, value: value)
            }
        )
    }

    // MARK: - Address and password

    /// Moves the account to a new address. The server mails a confirmation link to it and marks
    /// it unconfirmed, which is what the account shows from then on.
    func changeEmail(to email: String) async throws {
        try await updateUserAttribute("email", value: email)
        account?.email = email
        account?.isEmailValidated = false
        myUser?.email = email
    }

    /// Asks inventaire.io to mail the confirmation link again.
    func resendEmailConfirmation() async throws {
        let _: OkStatusDTO? = try await apiService.send(
            toEndpoint: "/api/auth/email-confirmation",
            method: "POST"
        )
    }

    /// `PUT /api/auth/password`. The session survives it: the server only rewrites the hash.
    func changePassword(current: String, new: String) async throws(PasswordChangeFailure) {
        do {
            let _: OkStatusDTO? = try await apiService.send(
                toEndpoint: "/api/auth/password",
                method: "PUT",
                payload: PasswordChangePayload(currentPassword: current, newPassword: new)
            )
        } catch {
            throw PasswordChangeFailure(error: error)
        }
    }
}
