//
//  AutoSortName.swift
//  ReCIT_iOS
//
//  One place that decides when two names written by a language model are the same
//  name. Both halves of the auto-sort pipeline need it: genres arrive as Wikidata
//  labels whose spelling we do not control, and shelf names come back from the
//  model as free text that may differ from the taxonomy it was handed by nothing
//  more than a capital or an accent.
//
//  Folding case *and* diacritics is deliberate. "Poesie" and "poésie" are the same
//  rayon to a reader, and a model that drops an accent must not thereby invent a
//  second étagère — nor be accused of hallucinating one. The comparison is loose;
//  the *canonical spelling* is always the one the taxonomy declared, never the
//  model's variant, so what the user reads is what phase 1 proposed.
//
//  See PRD 0006.
//

import Foundation

enum AutoSortName {

    /// French, because every prompt in this pipeline is French and the folding of
    /// a French label should not depend on the device's locale.
    private static let locale: Locale = .init(identifier: "fr_FR")

    /// The name as it should be shown: surrounding whitespace gone, `nil` when
    /// nothing is left. A blank name is not a name, and treating it as one is how
    /// an empty étagère reaches a plan.
    static func trimmed(_ raw: String) -> String? {
        let trimmed: String = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The identity two names are compared on. `nil` for a blank name, so callers
    /// get one guard instead of two.
    static func key(_ raw: String) -> String? {
        guard let trimmed = trimmed(raw) else { return nil }
        return trimmed.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: locale
        )
    }
}
