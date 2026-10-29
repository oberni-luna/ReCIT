//
//  EditionLanguageFilter.swift
//  ReCIT_iOS
//
//  Which editions of a work « Éditions » shows: all of them, those in one language, or those
//  whose language nobody has said. A work can have thousands of editions — « L'Appel de la
//  forêt » has 7742 —, and the list is read in one language at a time.
//
//  The language is the edition's own, `Edition.lang` (`wdt:P407`, which inventaire.io answers as
//  `originalLang`), never guessed: most Wikidata editions have none, and they are listed under
//  `.unspecified` rather than counted where they probably belong.
//
//  Pure, and `nonisolated`: « Éditions » works its list out off the main actor.
//

import Foundation

nonisolated enum EditionLanguageFilter: Hashable, Sendable {
    case all
    case code(String)
    case unspecified

    /// The language an edition carries, as this filter reads it: lowercased, and none when empty.
    static func normalized(_ lang: String?) -> String? {
        guard let lang = lang?.trimmingCharacters(in: .whitespaces).lowercased(), lang.isEmpty == false else { return nil }
        return lang
    }

    func admits(_ lang: String?) -> Bool {
        switch self {
        case .all:
            return true
        case .code(let code):
            return Self.normalized(lang) == code
        case .unspecified:
            return Self.normalized(lang) == nil
        }
    }

    /// What the menu offers for editions in `langs`: every edition first, then each language
    /// present, the one with the most editions first, then the editions without a language when
    /// there are some.
    static func options(of langs: [String?]) -> [EditionLanguageFilterOption] {
        var counts: [String: Int] = [:]
        var unspecifiedCount: Int = 0
        for lang in langs {
            if let code = normalized(lang) {
                counts[code, default: 0] += 1
            } else {
                unspecifiedCount += 1
            }
        }

        let languages: [EditionLanguageFilterOption] = counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .map { .init(language: .code($0.key), count: $0.value) }
        let unspecified: [EditionLanguageFilterOption] = unspecifiedCount > 0
            ? [.init(language: .unspecified, count: unspecifiedCount)]
            : []
        return [.init(language: .all, count: langs.count)] + languages + unspecified
    }

    /// The language shown until somebody picks one: the phone's, when the work has editions in
    /// it, every edition otherwise.
    static func preferred(_ phoneLanguage: String?, among options: [EditionLanguageFilterOption]) -> EditionLanguageFilter {
        guard let code = normalized(phoneLanguage), options.contains(where: { $0.language == .code(code) }) else { return .all }
        return .code(code)
    }

    /// The language's name in `locale`, capitalized as the start of a label: « Français »,
    /// « Anglais ». A code the locale cannot name is shown as it is.
    static func name(of code: String, in locale: Locale) -> String {
        let name: String = locale.localizedString(forIdentifier: code)
            ?? locale.localizedString(forLanguageCode: code)
            ?? code
        guard let first = name.first else { return code }
        return String(first).uppercased(with: locale) + name.dropFirst()
    }

    /// For `NavigationDestination.id`.
    var id: String {
        switch self {
        case .all:
            "all"
        case .code(let code):
            code
        case .unspecified:
            "unspecified"
        }
    }
}
