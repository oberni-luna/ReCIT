//
//  GenreCoverage.swift
//  ReCIT_iOS
//
//  How much of the library the genre backfill actually managed to describe.
//  Wikidata's genre data for French mid-list titles is thin, so this tally is
//  the first honest signal on whether an AI shelf taxonomy built from it is
//  worth having — hence it is reported, not hidden behind a success flag.
//

import Foundation

struct GenreCoverage: Equatable {

    /// Works behind the user's unshelved books, deduplicated.
    let worksConsidered: Int

    /// Works enriched and carrying at least one genre.
    let worksWithGenres: Int

    /// Works enriched whose entity simply has no `wdt:P136` claim. A valid
    /// outcome, not a failure — these books stay unshelved rather than guessed.
    let worksWithoutGenres: Int

    /// Works never enriched, or whose entity did not come back. Non-zero after a
    /// failed run; zero after a complete one.
    let worksPending: Int

    static let empty: GenreCoverage = .init(
        worksConsidered: 0,
        worksWithGenres: 0,
        worksWithoutGenres: 0,
        worksPending: 0
    )

    /// Share of considered works that ended up with usable genre data, 0…1.
    var genreRatio: Double {
        guard worksConsidered > 0 else { return 0 }
        return Double(worksWithGenres) / Double(worksConsidered)
    }

    /// Tallies a set of works. `@MainActor` because `Work` is a SwiftData model
    /// read on the main context.
    @MainActor
    init(works: [Work]) {
        var withGenres: Int = 0
        var withoutGenres: Int = 0
        var pending: Int = 0

        for work in works {
            // A work asked under an older claim reading is pending, not answered: it is about
            // to be re-asked, and counting it as "no genre" would report thin data where the
            // truth is stale data. See `GenreClaims.revision`.
            if work.genresEnrichedAt == nil || work.genresRevision < GenreClaims.revision {
                pending += 1
            } else if work.genres.isEmpty {
                withoutGenres += 1
            } else {
                withGenres += 1
            }
        }

        self.init(
            worksConsidered: works.count,
            worksWithGenres: withGenres,
            worksWithoutGenres: withoutGenres,
            worksPending: pending
        )
    }

    private init(
        worksConsidered: Int,
        worksWithGenres: Int,
        worksWithoutGenres: Int,
        worksPending: Int
    ) {
        self.worksConsidered = worksConsidered
        self.worksWithGenres = worksWithGenres
        self.worksWithoutGenres = worksWithoutGenres
        self.worksPending = worksPending
    }
}
