//
//  ValidatedGenreMapping.swift
//  ReCIT_iOS
//
//  What phase 2 is allowed to hand to phase 3: a genre → étagère mapping in which
//  every étagère is one phase 1 declared, spelled the way phase 1 spelled it.
//
//  There is deliberately no public initialiser other than the validator's. The
//  only way to obtain one of these is to have passed the checks in
//  `ShelfMappingValidator`, so a hallucinated shelf name has no route into the
//  plan — and therefore none into the user's data, since phase 3 is plain code.
//  See PRD 0006.
//

import Foundation

struct ValidatedGenreMapping: Equatable, Sendable {

    /// The étagères phase 1 declared, canonical spelling, declaration order,
    /// deduplicated. Every value in `shelfByGenreKey` is one of these.
    let shelfNames: [String]

    /// Genre identity → canonical étagère name. Keyed on `AutoSortName.key` so a
    /// lookup tolerates the same spelling drift the validator forgave.
    let shelfByGenreKey: [String: String]

    /// Genres that were offered to phase 2 and came back unassigned — omitted from
    /// the response, or rejected by it. Their books stay unshelved.
    let unmappedGenres: [String]

    /// Everything the validator threw away, kept for logging and for the human
    /// gate: a run whose mapping was half hallucinated is worth knowing about even
    /// when the surviving half is usable.
    let rejections: [ShelfMappingValidator.Rejection]

    /// The étagère a book of this genre belongs on, or `nil` if the genre was never
    /// validly mapped — in which case the book is left alone.
    func shelfName(forGenre genre: String) -> String? {
        guard let key = AutoSortName.key(genre) else { return nil }
        return shelfByGenreKey[key]
    }

    /// Internal so only the validator can build one.
    init(
        shelfNames: [String],
        shelfByGenreKey: [String: String],
        unmappedGenres: [String],
        rejections: [ShelfMappingValidator.Rejection]
    ) {
        self.shelfNames = shelfNames
        self.shelfByGenreKey = shelfByGenreKey
        self.unmappedGenres = unmappedGenres
        self.rejections = rejections
    }
}
