//
//  ReportMailDraft.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/09/2026.
//

import Foundation

/// The mail a « Signalement » opens: who is being reported, in which exchange, and by whom.
///
/// A pure value type on purpose — no SwiftUI, no `UIApplication`. It only knows how to turn a
/// report into a `mailto:` URL, so the subject, the body and the escaping can be tested without
/// a simulator and without a mail client.
struct ReportMailDraft {
    /// The moderation mailbox. Reports are mail, not an API call: there is no server-side
    /// report endpoint on inventaire.io, and the app must still offer the mechanism.
    static let recipient: String = "ex-libris@lunabee.com"

    let reportedUsername: String
    let reportedUserId: String
    /// Set when the report is about a transaction's message exchange rather than the person.
    let transactionId: String?
    let reporterUsername: String?
    let appVersion: String?

    init(
        reportedUsername: String,
        reportedUserId: String,
        transactionId: String? = nil,
        reporterUsername: String? = nil,
        appVersion: String? = ReportMailDraft.bundleVersion
    ) {
        self.reportedUsername = reportedUsername
        self.reportedUserId = reportedUserId
        self.transactionId = transactionId
        self.reporterUsername = reporterUsername
        self.appVersion = appVersion
    }

    /// « Signalement : alice » — plus « — <id de transaction> » when the report names an exchange.
    var subject: String {
        if let transactionId {
            String(localized: "report.subject.transaction \(reportedUsername) \(transactionId)")
        } else {
            String(localized: "report.subject.user \(reportedUsername)")
        }
    }

    /// An invitation to describe the problem, then the facts the reporter would never think to
    /// copy by hand. The free text comes first so the cursor lands where the writing happens.
    var body: String {
        var lines: [String] = [
            String(localized: "report.body.intro"),
            "",
            "",
            "—",
            String(localized: "report.body.user \(reportedUsername) \(reportedUserId)")
        ]

        if let transactionId {
            lines.append(String(localized: "report.body.transaction \(transactionId)"))
        }
        if let reporterUsername {
            lines.append(String(localized: "report.body.reporter \(reporterUsername)"))
        }
        if let appVersion {
            lines.append(String(localized: "report.body.version \(appVersion)"))
        }

        return lines.joined(separator: "\n")
    }

    var mailtoURL: URL? {
        var components: URLComponents = .init()
        components.scheme = "mailto"
        components.path = Self.recipient
        // `queryItems` leaves `&` and `+` alone inside values, which a username or a message
        // body can perfectly well contain — hence the hand-rolled escaping.
        components.percentEncodedQueryItems = [
            .init(name: "subject", value: Self.escape(subject)),
            .init(name: "body", value: Self.escape(body))
        ]
        return components.url
    }

    /// `.urlQueryAllowed` keeps the sub-delimiters that separate a query; a *value* must not.
    private static let queryValueAllowed: CharacterSet = .urlQueryAllowed
        .subtracting(.init(charactersIn: "&=+?#;"))

    private static func escape(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? value
    }

    /// "1.4 (23)", or `nil` in the unlikely case the bundle carries neither.
    static var bundleVersion: String? {
        let short: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return switch (short, build) {
        case (let short?, let build?): "\(short) (\(build))"
        case (let short?, nil): short
        case (nil, let build?): build
        default: nil
        }
    }
}
