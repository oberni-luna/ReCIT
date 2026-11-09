//
//  AccountSettings.swift
//  ReCIT_iOS
//
//  What only the owner of an account sees of it: the address and whether it is confirmed, the
//  language inventaire.io writes in, the two visibility switches, the e-mails it sends, and
//  whether a Wikidata account is linked.
//
//  A value held by `UserModel.account`, not a SwiftData model: none of it is ever shown for anyone
//  else, it is read again from `GET /api/user` at every launch, and a dozen switches were not worth
//  a store migration. Everything public about the account — name, picture, bio, position — is on
//  `User`, where a friend's profile reads it too.
//

import Foundation

struct AccountSettings: Equatable, Sendable {
    /// The server's reading of an absent `summaryPeriodicity`
    /// (`server/db/couchdb/design_docs/users.ts`).
    static let defaultSummaryPeriodicity: Int = 20

    /// The key `GET /api/user` lists in `enabledOAuth` once an account is linked, on the
    /// inventaire.io website.
    private static let wikidataOAuthProvider: String = "wikidata"

    var email: String?
    var isEmailValidated: Bool
    var language: String?
    var isFediversable: Bool
    var anonymizesContributions: Bool
    var summaryPeriodicity: Int
    /// Whether the account holds Wikidata tokens: what changes on a Wikidata work or person is
    /// then published under the reader's own Wikidata account rather than by inventaire.io's bot.
    var linksWikidata: Bool
    private var notifications: [NotificationSetting: Bool]

    init(
        email: String?,
        isEmailValidated: Bool,
        language: String?,
        isFediversable: Bool,
        anonymizesContributions: Bool,
        summaryPeriodicity: Int,
        notifications: [NotificationSetting: Bool],
        linksWikidata: Bool = false
    ) {
        self.email = email
        self.isEmailValidated = isEmailValidated
        self.language = language
        self.isFediversable = isFediversable
        self.anonymizesContributions = anonymizesContributions
        self.summaryPeriodicity = summaryPeriodicity
        self.notifications = notifications
        self.linksWikidata = linksWikidata
    }

    /// An absent switch is read the way the server reads it: on. A confirmation nobody mentions is
    /// not assumed, though — `validEmail` is always served to the owner, and a missing one is the
    /// shape of a payload that was not the owner's.
    init(userDTO: UserDTO) {
        let notifications: [NotificationSetting: Bool] = Dictionary(
            uniqueKeysWithValues: (userDTO.settings?.notifications ?? [:]).compactMap { key, value in
                NotificationSetting(rawValue: key).map { ($0, value) }
            }
        )

        self.init(
            email: userDTO.email,
            isEmailValidated: userDTO.validEmail ?? false,
            language: userDTO.language,
            isFediversable: userDTO.fediversable ?? false,
            anonymizesContributions: userDTO.settings?.contributions?["anonymize"] ?? true,
            summaryPeriodicity: userDTO.summaryPeriodicity ?? Self.defaultSummaryPeriodicity,
            notifications: notifications,
            linksWikidata: userDTO.enabledOAuth?.contains(Self.wikidataOAuthProvider) ?? false
        )
    }

    func isEnabled(_ setting: NotificationSetting) -> Bool {
        notifications[setting] ?? true
    }

    mutating func set(_ setting: NotificationSetting, to isEnabled: Bool) {
        notifications[setting] = isEnabled
    }
}
