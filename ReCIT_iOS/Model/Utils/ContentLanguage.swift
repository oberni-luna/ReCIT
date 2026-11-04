//
//  ContentLanguage.swift
//  ReCIT_iOS
//
//  The language inventaire.io is asked to answer in — names, titles, descriptions, genres,
//  Wikipedia summaries, search results. It is the phone's, so a reader whose phone is in English
//  reads « French novelist, poet, dramatist and politician » under Victor Hugo, and « The
//  Hunchback of Notre-Dame » among his works. Until 2026-10-30 it was `"fr"`, hard-coded in a
//  dozen requests.
//
//  Read from `Locale.preferredLanguages` rather than `Locale.current`: the app is localised in
//  English and French only, and for a phone set to Japanese `Locale.current` answers with the
//  language the app fell back to, English, where Wikidata has a Japanese name to offer.
//
//  `by-uris` returns one language per entity: the one asked for, or one of the server's choosing
//  when it has none. What is already in the store stays in the language it was fetched in until
//  the entity is fetched again.
//
//  `nonisolated` because it is the default value of parameters, and a default is evaluated at the
//  call site, which is not necessarily on the main actor. It reads a system preference and keeps
//  no state, so there is nothing for an actor to guard.
//

import Foundation

nonisolated enum ContentLanguage {
    /// The phone's first preferred language, as a bare code — `en` for `en-FR`, `pt` for `pt-BR`.
    /// French when the phone names none, as the app always read.
    static var preferred: String {
        code(of: Locale.preferredLanguages.first) ?? "fr"
    }

    /// The language code of a BCP 47 identifier, lowercased, `nil` when there is none.
    static func code(of identifier: String?) -> String? {
        guard let identifier, identifier.isEmpty == false else { return nil }
        return Locale.Language(identifier: identifier).languageCode?.identifier.lowercased()
    }
}
