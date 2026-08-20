//
//  ShelfMappingValidator.swift
//  ReCIT_iOS
//
//  The seam. Everything upstream of here is a language model's opinion;
//  everything downstream is plain code that will eventually create étagères and
//  file books into them. This is the one place that decides which of those
//  opinions is allowed across.
//
//  Two things are checked, and they are symmetric. An étagère phase 2 names that
//  phase 1 never declared is a hallucination — the model was handed a closed list
//  and answered outside it. A genre phase 2 names that was never in the histogram
//  is the same failure in the other direction — an invented genre would carry
//  along an invented set of books. Both are rejected outright; neither is
//  repaired, because a guess about what the model *meant* is exactly the kind of
//  cleverness that lets a bad name through.
//
//  What is forgiven is spelling: case and accents drift constantly in generated
//  French, and a dropped accent is not an invention. The name that survives is
//  always phase 1's, never the model's variant, so the user reads the taxonomy
//  they were shown.
//
//  Rejection is per-assignment; failure is wholesale. A response that yields no
//  usable assignment at all throws rather than returning an empty mapping: an
//  empty mapping would flow harmlessly into a plan with no étagères and read to
//  the user as "your library has no genres", which is a lie about the data.
//
//  Pure by design — no store, no model, no SwiftUI. See PRD 0006.
//

import Foundation

enum ShelfMappingValidator {

    /// One line of phase 2's output, before anything has been checked.
    struct RawAssignment: Equatable, Sendable {
        let genre: String
        let shelfName: String

        init(genre: String, shelfName: String) {
            self.genre = genre
            self.shelfName = shelfName
        }
    }

    /// Why one assignment was thrown away. Recorded rather than merely counted so
    /// a bad prompt can be diagnosed from the log during prompt tuning.
    enum Rejection: Equatable, Sendable {
        /// The étagère is not one phase 1 declared. The hallucination this whole
        /// module exists for.
        case undeclaredShelf(genre: String, proposed: String)
        /// The genre was never in the histogram, so no book carries it.
        case unknownGenre(genre: String, proposed: String)
        /// Genre or étagère came back blank.
        case blankName
        /// The genre had already been assigned; the first assignment stands.
        case duplicateGenre(genre: String)
    }

    /// A response too broken to take anything from.
    enum Failure: Error, Equatable {
        /// Phase 1 declared no usable étagère, so phase 2 had no closed list to
        /// answer from and nothing can be validated against.
        case emptyTaxonomy
        /// Phase 2 returned no assignment at all.
        case emptyResponse
        /// Phase 2 returned assignments, and not one of them survived.
        case nothingUsable
    }

    /// - Parameters:
    ///   - taxonomy: the étagère names phase 1 declared, in the order it declared them.
    ///   - assignments: phase 2's raw output, unchecked.
    ///   - offeredGenres: the distinct genres phase 2 was actually shown — the
    ///     histogram's labels. Anything outside this set is an invention.
    static func validate(
        taxonomy: [String],
        assignments: [RawAssignment],
        offeredGenres: [String]
    ) throws -> ValidatedGenreMapping {
        // Canonical taxonomy first: trim, drop blanks, and collapse case- or
        // accent-differing duplicates onto the first spelling declared. Done here
        // rather than in the model type so "the taxonomy" means one thing.
        var shelfNames: [String] = []
        var canonicalShelfByKey: [String: String] = [:]
        for name in taxonomy {
            guard let trimmed = AutoSortName.trimmed(name), let key = AutoSortName.key(name) else { continue }
            guard canonicalShelfByKey[key] == nil else { continue }
            canonicalShelfByKey[key] = trimmed
            shelfNames.append(trimmed)
        }
        guard !shelfNames.isEmpty else { throw Failure.emptyTaxonomy }

        // The closed set of genres, canonicalised the same way.
        var offeredOrder: [String] = []
        var canonicalGenreByKey: [String: String] = [:]
        for genre in offeredGenres {
            guard let trimmed = AutoSortName.trimmed(genre), let key = AutoSortName.key(genre) else { continue }
            guard canonicalGenreByKey[key] == nil else { continue }
            canonicalGenreByKey[key] = trimmed
            offeredOrder.append(key)
        }

        guard !assignments.isEmpty else { throw Failure.emptyResponse }

        var shelfByGenreKey: [String: String] = [:]
        var rejections: [Rejection] = []

        for assignment in assignments {
            guard let genreKey = AutoSortName.key(assignment.genre),
                  let shelfKey = AutoSortName.key(assignment.shelfName) else {
                rejections.append(.blankName)
                continue
            }
            guard let genre = canonicalGenreByKey[genreKey] else {
                rejections.append(.unknownGenre(genre: assignment.genre, proposed: assignment.shelfName))
                continue
            }
            guard let shelf = canonicalShelfByKey[shelfKey] else {
                rejections.append(.undeclaredShelf(genre: genre, proposed: assignment.shelfName))
                continue
            }
            guard shelfByGenreKey[genreKey] == nil else {
                // First assignment wins, so a model that answers twice for one
                // genre resolves the same way on every run.
                rejections.append(.duplicateGenre(genre: genre))
                continue
            }
            shelfByGenreKey[genreKey] = shelf
        }

        guard !shelfByGenreKey.isEmpty else { throw Failure.nothingUsable }

        // An omitted genre is not an error — the model may simply have run out of
        // response — but its books must not be filed on a guess, so it is reported
        // and left out.
        let unmappedGenres: [String] = offeredOrder
            .filter { shelfByGenreKey[$0] == nil }
            .compactMap { canonicalGenreByKey[$0] }

        return .init(
            shelfNames: shelfNames,
            shelfByGenreKey: shelfByGenreKey,
            unmappedGenres: unmappedGenres,
            rejections: rejections
        )
    }
}
