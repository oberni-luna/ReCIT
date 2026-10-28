//
//  AccountLanguage.swift
//  ReCIT_iOS
//
//  The languages inventaire.io can write its e-mails in and name works in — the 29 codes `PUT
//  /api/user` accepts for `language` — each named in the phone's own language.
//

import Foundation

struct AccountLanguage: Identifiable, Equatable {
    /// `translatedLanguagesData` in the server, as its API documentation lists it.
    static let codes: [String] = [
        "ar", "bn", "ca", "cs", "da", "de", "el", "en", "eo", "es", "fi", "fr", "hu", "id", "it",
        "ja", "nb", "nl", "pa", "pl", "pt", "ro", "ru", "sk", "sv", "th", "tr", "uk", "zh",
    ]

    let code: String
    let name: String

    var id: String { code }

    /// Every language, sorted by its name as the phone spells it.
    static func all(locale: Locale = .current) -> [AccountLanguage] {
        codes
            .map { AccountLanguage(code: $0, name: name(of: $0, locale: locale)) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func name(of code: String, locale: Locale = .current) -> String {
        guard let name = locale.localizedString(forLanguageCode: code) else { return code }
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}
