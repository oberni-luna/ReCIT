//
//  EntityDescription.swift
//  ReCIT_iOS
//
//  The one line under an author's or a work's name — « romancier, poète, dramaturge… » — picked
//  from the descriptions inventaire.io relays from Wikidata.
//
//  It used to be `descriptions["fr"] ?? descriptions["en"]`, which on a phone in English showed
//  Victor Hugo described in French. The order now: the phone's language (`ContentLanguage`),
//  which is also the one `by-uris` is asked for; then French and English, as the app always read
//  them; and, when none of those exist, the smallest language code — the server, asked for a
//  language it has no description in, answers with another of its choosing, and a description in
//  that language is still the entity's.
//
//  `nil` means there is no non-empty description at all.
//

import Foundation

enum EntityDescription {
    /// The description to display, or `nil` when the entity has none.
    static func resolve(
        _ descriptions: [String: String]?,
        preferredLanguage: String = ContentLanguage.preferred
    ) -> String? {
        guard let descriptions else { return nil }

        for language in [preferredLanguage, "fr", "en"] {
            if let description = descriptions[language], description.isEmpty == false {
                return description
            }
        }

        return descriptions
            .filter { $0.value.isEmpty == false }
            .min { $0.key < $1.key }?
            .value
    }
}
