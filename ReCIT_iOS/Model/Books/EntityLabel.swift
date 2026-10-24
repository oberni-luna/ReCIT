//
//  EntityLabel.swift
//  ReCIT_iOS
//
//  The name a work, an author or a genre wears on screen, picked from the labels inventaire.io
//  relays from Wikidata.
//
//  It exists because Wikidata has been moving names that read the same in every Latin-script
//  language to the multilingual `mul` label, and deleting the per-language copies. `wd:Q535`
//  carries « Victor Hugo » under `mul` and nowhere under `fr` or `en` (checked on 2026-10-24),
//  so an author read as `labels["fr"] ?? labels["en"] ?? ""` came out with no name at all, and
//  the book screen showed his portrait beside an empty line. Works fell back to
//  `labels.values.first`, which is whichever language the dictionary hashes first — Russian as
//  easily as Japanese.
//
//  The order: French and English first, as the app always read them; then `mul`, which is the
//  name itself rather than a translation of it; then the entity's original language; and, when
//  none of those exist, the smallest language code, so the same entity is named the same way
//  on every sync.
//
//  `nil` means there is no non-empty label at all. Editions are named by `EditionTitle`, whose
//  `fromclaims` and title claim do not exist for works and authors.
//

import Foundation

enum EntityLabel {
    /// The label to display, or `nil` when the entity has none.
    static func resolve(
        _ labels: [String: String]?,
        originalLang: String? = nil
    ) -> String? {
        guard let labels else { return nil }

        let preferred: [String?] = ["fr", "en", "mul", originalLang]
        for case let language? in preferred {
            if let label = labels[language], label.isEmpty == false {
                return label
            }
        }

        return labels
            .filter { $0.value.isEmpty == false }
            .min { $0.key < $1.key }?
            .value
    }
}
