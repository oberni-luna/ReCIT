//
//  AccountSettingsView.swift
//  ReCIT_iOS
//
//  « Compte et connexion » (`A6` in the Figma file): the address and the password, each behind a
//  screen of its own, then the language of the account and two switches about who sees what.
//  No « Enregistrer »: the menu and the switches write themselves, optimistic, and go back with a
//  SnackBar if the server refuses (`UserModel+Account`).
//

import SwiftUI
import SwiftData

struct AccountSettingsView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DesignSystem.Form {
            if let account = userModel.account {
                if account.isEmailValidated == false, let email = account.email {
                    EmailConfirmationNotice(email: email)
                }

                Section {
                    NavigationLink(value: NavigationDestination.changeEmail) {
                        Text(account.email ?? "")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                            .withLabel(label: "account.email")
                    }
                    .accessibilityIdentifier("e2e.account.email")

                    NavigationLink(value: NavigationDestination.changePassword) {
                        Text(verbatim: "••••••••••")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                            .withLabel(label: "account.password")
                    }
                    .accessibilityIdentifier("e2e.account.password")
                } header: {
                    CreateBookSectionHeader("account.sign_in.header")
                }

                Section {
                    Picker(selection: languageBinding(account)) {
                        ForEach(AccountLanguage.all()) { language in
                            Text(language.name).tag(language.code)
                        }
                    } label: {
                        Text("account.language")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("e2e.account.language")
                } header: {
                    CreateBookSectionHeader("account.language.header")
                } footer: {
                    CreateBookSectionFooter("account.language.footer")
                }

                Section {
                    Toggle(isOn: fediversableBinding(account)) {
                        AccountToggleLabel(title: "account.fediverse", detail: "account.fediverse.detail")
                    }
                    .accessibilityIdentifier("e2e.account.fediverse")

                    Toggle(isOn: anonymizeBinding(account)) {
                        AccountToggleLabel(title: "account.anonymize", detail: "account.anonymize.detail")
                    }
                    .accessibilityIdentifier("e2e.account.anonymize")
                } header: {
                    CreateBookSectionHeader("account.visibility.header")
                }
                .tint(.backgroundTintedInverse)
            } else {
                Section {
                    SyncingInlineRow()
                }
            }
        }
        .navigationTitle("account.title")
    }

    private func languageBinding(_ account: AccountSettings) -> Binding<String> {
        .init(
            get: { account.language ?? "" },
            set: { userModel.setLanguage($0, modelContext: modelContext) }
        )
    }

    private func fediversableBinding(_ account: AccountSettings) -> Binding<Bool> {
        .init(
            get: { account.isFediversable },
            set: { userModel.setFediversable($0, modelContext: modelContext) }
        )
    }

    private func anonymizeBinding(_ account: AccountSettings) -> Binding<Bool> {
        .init(
            get: { account.anonymizesContributions },
            set: { userModel.setAnonymizesContributions($0, modelContext: modelContext) }
        )
    }
}
