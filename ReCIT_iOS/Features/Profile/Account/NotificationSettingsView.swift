//
//  NotificationSettingsView.swift
//  ReCIT_iOS
//
//  « Notifications par e-mail » (`A9` in the Figma file): which e-mails inventaire.io sends, one
//  switch per key of `settings.notifications`, and how often the activity summary comes. Every
//  switch writes itself, optimistic; the general one, off, greys the others — they keep their
//  value, but nothing is sent.
//

import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    /// The periodicities the menu offers, in days; 20 is the server's own default.
    private static let periodicities: [Int] = [1, 7, 14, 20, 30]

    var body: some View {
        DesignSystem.Form {
            if let account = userModel.account {
                let isGlobalOn: Bool = account.isEnabled(.global)

                Section {
                    toggle(.global, account: account, title: "notifications.global", detail: "notifications.global.detail")
                }

                Section {
                    toggle(
                        .inventoriesActivitySummary,
                        account: account,
                        title: "notifications.summary",
                        detail: "notifications.summary.detail"
                    )

                    Picker(selection: periodicityBinding(account)) {
                        ForEach(periodicities(including: account.summaryPeriodicity), id: \.self) { days in
                            Text("notifications.summary.every \(days)").tag(days)
                        }
                    } label: {
                        Text("notifications.summary.periodicity")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                    }
                    .pickerStyle(.menu)
                    .disabled(account.isEnabled(.inventoriesActivitySummary) == false)
                    .accessibilityIdentifier("e2e.notifications.periodicity")
                } header: {
                    CreateBookSectionHeader("notifications.summary.header")
                }
                .disabled(isGlobalOn == false)

                Section {
                    toggle(.friendshipRequest, account: account, title: "notifications.friendship_request")
                    toggle(.friendAcceptedRequest, account: account, title: "notifications.friend_accepted_request")
                } header: {
                    CreateBookSectionHeader("notifications.friends.header")
                }
                .disabled(isGlobalOn == false)

                Section {
                    toggle(.groupInvite, account: account, title: "notifications.group_invite")
                    toggle(.groupAcceptRequest, account: account, title: "notifications.group_accept_request")
                    toggle(.groupJoinRequest, account: account, title: "notifications.group_join_request")
                } header: {
                    CreateBookSectionHeader("notifications.groups.header")
                }
                .disabled(isGlobalOn == false)

                Section {
                    toggle(.yourItemWasRequested, account: account, title: "notifications.your_item_was_requested")
                    toggle(.updateOnYourItem, account: account, title: "notifications.update_on_your_item")
                    toggle(.updateOnItemYouRequested, account: account, title: "notifications.update_on_item_you_requested")
                } header: {
                    CreateBookSectionHeader("notifications.transactions.header")
                }
                .disabled(isGlobalOn == false)
            } else {
                Section {
                    SyncingInlineRow()
                }
            }
        }
        .tint(.backgroundTintedInverse)
        .navigationTitle("notifications.title")
    }

    private func toggle(
        _ setting: NotificationSetting,
        account: AccountSettings,
        title: LocalizedStringKey,
        detail: LocalizedStringKey? = nil
    ) -> some View {
        Toggle(
            isOn: .init(
                get: { account.isEnabled(setting) },
                set: { userModel.setNotification(setting, to: $0, modelContext: modelContext) }
            )
        ) {
            AccountToggleLabel(title: title, detail: detail)
        }
        .accessibilityIdentifier("e2e.notifications.\(setting.rawValue)")
    }

    private func periodicityBinding(_ account: AccountSettings) -> Binding<Int> {
        .init(
            get: { account.summaryPeriodicity },
            set: { userModel.setSummaryPeriodicity($0, modelContext: modelContext) }
        )
    }

    /// The menu's values, plus the account's own when the website set one the menu lacks.
    private func periodicities(including current: Int) -> [Int] {
        Self.periodicities.contains(current) ? Self.periodicities : (Self.periodicities + [current]).sorted()
    }
}
