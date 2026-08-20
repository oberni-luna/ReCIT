//
//  ShelfMappingValidatorTests.swift
//  ReCIT_iOSTests
//
//  The guard that stops a hallucinated étagère reaching the user's data, and
//  therefore the suite that deserves the most coverage in this feature. Pure and
//  network-free: no model, no store, no SwiftUI.
//
//  The model's own output is deliberately *not* tested anywhere — it is
//  non-deterministic by nature, which is precisely why everything around it is
//  pure. What is pinned here is the contract that holds whatever the model says:
//  every étagère in the result was declared by phase 1, spelled phase 1's way; no
//  genre in the result was absent from the histogram; and a response too broken to
//  trust is refused whole rather than half-accepted.
//
//  See PRD 0006.
//

import Testing
@testable import ReCIT_iOS

@Suite("ShelfMappingValidator")
struct ShelfMappingValidatorTests {

    private let taxonomy: [String] = [
        "Littérature de l'imaginaire",
        "Romans policiers",
        "Essais et documents"
    ]

    private let genres: [String] = [
        "science-fiction",
        "fantasy",
        "roman policier",
        "essai",
        "poésie"
    ]

    private func assignment(_ genre: String, _ shelf: String) -> ShelfMappingValidator.RawAssignment {
        .init(genre: genre, shelfName: shelf)
    }

    private func validate(
        taxonomy: [String]? = nil,
        _ assignments: [ShelfMappingValidator.RawAssignment],
        genres: [String]? = nil
    ) throws -> ValidatedGenreMapping {
        try ShelfMappingValidator.validate(
            taxonomy: taxonomy ?? self.taxonomy,
            assignments: assignments,
            offeredGenres: genres ?? self.genres
        )
    }

    // MARK: - The happy path

    @Test func aMappingUsingOnlyDeclaredNamesPasses() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("science-fiction", "Littérature de l'imaginaire"),
            assignment("fantasy", "Littérature de l'imaginaire"),
            assignment("roman policier", "Romans policiers"),
            assignment("essai", "Essais et documents"),
            assignment("poésie", "Essais et documents")
        ])

        #expect(mapping.rejections.isEmpty)
        #expect(mapping.unmappedGenres.isEmpty)
        #expect(mapping.shelfName(forGenre: "science-fiction") == "Littérature de l'imaginaire")
        #expect(mapping.shelfName(forGenre: "roman policier") == "Romans policiers")
        #expect(mapping.shelfName(forGenre: "poésie") == "Essais et documents")
    }

    @Test func theDeclaredTaxonomyKeepsItsDeclarationOrder() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("essai", "Essais et documents")
        ])

        #expect(mapping.shelfNames == taxonomy)
    }

    /// The invariant the whole design rests on, asserted directly: whatever comes
    /// out, every étagère it names is one phase 1 declared.
    @Test func everyShelfInTheResultWasDeclaredByPhaseOne() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("science-fiction", "Littérature de l'imaginaire"),
            assignment("fantasy", "Rayon fantasy"),
            assignment("essai", "ESSAIS ET DOCUMENTS")
        ])

        let declared: Set<String> = .init(taxonomy)
        #expect(mapping.shelfByGenreKey.values.allSatisfy { declared.contains($0) })
    }

    // MARK: - Invented étagères

    @Test func anInventedShelfNameIsRejected() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("science-fiction", "Littérature de l'imaginaire"),
            assignment("fantasy", "Mondes merveilleux")
        ])

        #expect(mapping.shelfName(forGenre: "fantasy") == nil)
        #expect(mapping.rejections == [.undeclaredShelf(genre: "fantasy", proposed: "Mondes merveilleux")])
    }

    /// One bad line must not poison the good ones — a run that loses a genre is
    /// still worth showing, a run that loses everything is not (below).
    @Test func anInventedNameDoesNotTakeTheValidAssignmentsWithIt() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("fantasy", "Mondes merveilleux"),
            assignment("science-fiction", "Littérature de l'imaginaire"),
            assignment("essai", "Essais et documents")
        ])

        #expect(mapping.shelfByGenreKey.count == 2)
        #expect(mapping.shelfName(forGenre: "science-fiction") == "Littérature de l'imaginaire")
        #expect(mapping.unmappedGenres.contains("fantasy"))
    }

    /// Matching is exact once case and accents are folded — no substring, no prefix,
    /// no "close enough". A near-miss is a name the user was never shown.
    @Test func aShelfNameThatIsOnlyASubstringOfADeclaredOneIsStillAnInvention() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("science-fiction", "Littérature de l'imaginaire"),
            assignment("essai", "Essais")
        ])

        #expect(mapping.shelfName(forGenre: "essai") == nil)
        #expect(mapping.rejections == [.undeclaredShelf(genre: "essai", proposed: "Essais")])
    }

    // MARK: - Invented genres

    @Test func aGenreThatWasNeverOfferedIsRejected() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("essai", "Essais et documents"),
            assignment("manga", "Littérature de l'imaginaire")
        ])

        #expect(mapping.shelfName(forGenre: "manga") == nil)
        #expect(mapping.rejections == [.unknownGenre(genre: "manga", proposed: "Littérature de l'imaginaire")])
    }

    /// Checked before the étagère, so an entirely invented line is reported as the
    /// invented *genre* it is rather than blamed on the shelf name.
    @Test func anInventedGenreIsReportedAsSuchEvenWhenTheShelfIsAlsoInvented() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("essai", "Essais et documents"),
            assignment("manga", "Rayon manga")
        ])

        #expect(mapping.rejections == [.unknownGenre(genre: "manga", proposed: "Rayon manga")])
    }

    // MARK: - Omissions

    @Test func anOmittedGenreIsReportedRatherThanGuessedAt() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("science-fiction", "Littérature de l'imaginaire"),
            assignment("essai", "Essais et documents")
        ])

        #expect(mapping.unmappedGenres == ["fantasy", "roman policier", "poésie"])
        #expect(mapping.shelfName(forGenre: "fantasy") == nil)
        #expect(mapping.rejections.isEmpty)
    }

    @Test func unmappedGenresFollowTheOrderTheyWereOfferedIn() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("poésie", "Essais et documents")
        ])

        #expect(mapping.unmappedGenres == ["science-fiction", "fantasy", "roman policier", "essai"])
    }

    // MARK: - Spelling drift resolves deterministically

    @Test func aCaseDifferingShelfNameResolvesToTheDeclaredSpelling() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("essai", "essais et documents")
        ])

        #expect(mapping.shelfName(forGenre: "essai") == "Essais et documents")
        #expect(mapping.rejections.isEmpty)
    }

    @Test func anAccentDifferingShelfNameResolvesToTheDeclaredSpelling() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("science-fiction", "Litterature de l'imaginaire")
        ])

        #expect(mapping.shelfName(forGenre: "science-fiction") == "Littérature de l'imaginaire")
    }

    @Test func aCaseDifferingGenreStillFindsItsOfferedLabel() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("Science-Fiction", "Littérature de l'imaginaire")
        ])

        #expect(mapping.shelfName(forGenre: "science-fiction") == "Littérature de l'imaginaire")
    }

    @Test func surroundingWhitespaceIsForgivenOnBothSides() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("  essai ", "  Essais et documents  ")
        ])

        #expect(mapping.shelfName(forGenre: "essai") == "Essais et documents")
    }

    /// Two spellings of one étagère must not become two étagères — that is the
    /// near-duplicate-shelf failure the whole three-phase split exists to avoid.
    @Test func caseDifferingDuplicatesInTheTaxonomyCollapseOntoTheFirstSpelling() throws {
        let mapping: ValidatedGenreMapping = try validate(
            taxonomy: ["Romans policiers", "romans policiers", "ROMANS POLICIERS"],
            [assignment("roman policier", "romans policiers")]
        )

        #expect(mapping.shelfNames == ["Romans policiers"])
        #expect(mapping.shelfName(forGenre: "roman policier") == "Romans policiers")
    }

    @Test func blankEntriesInTheTaxonomyAreDroppedNotDeclared() throws {
        let mapping: ValidatedGenreMapping = try validate(
            taxonomy: ["Essais et documents", "   ", ""],
            [assignment("essai", "Essais et documents")]
        )

        #expect(mapping.shelfNames == ["Essais et documents"])
    }

    // MARK: - Duplicates in the response

    @Test func aGenreAssignedTwiceKeepsTheFirstAssignment() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("essai", "Essais et documents"),
            assignment("essai", "Romans policiers")
        ])

        #expect(mapping.shelfName(forGenre: "essai") == "Essais et documents")
        #expect(mapping.rejections == [.duplicateGenre(genre: "essai")])
    }

    @Test func aGenreRepeatedWithADifferentSpellingIsStillADuplicate() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("poésie", "Essais et documents"),
            assignment("POESIE", "Romans policiers")
        ])

        #expect(mapping.shelfName(forGenre: "poésie") == "Essais et documents")
        #expect(mapping.rejections == [.duplicateGenre(genre: "poésie")])
    }

    // MARK: - Blank names

    @Test func aBlankShelfNameIsRejected() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("essai", "Essais et documents"),
            assignment("fantasy", "   ")
        ])

        #expect(mapping.rejections == [.blankName])
        #expect(mapping.shelfName(forGenre: "fantasy") == nil)
    }

    @Test func aBlankGenreIsRejected() throws {
        let mapping: ValidatedGenreMapping = try validate([
            assignment("essai", "Essais et documents"),
            assignment("", "Romans policiers")
        ])

        #expect(mapping.rejections == [.blankName])
    }

    // MARK: - Responses refused whole

    @Test func anEmptyTaxonomyThrows() {
        #expect(throws: ShelfMappingValidator.Failure.emptyTaxonomy) {
            try validate(taxonomy: [], [assignment("essai", "Essais et documents")])
        }
    }

    @Test func aTaxonomyOfNothingButBlanksThrows() {
        #expect(throws: ShelfMappingValidator.Failure.emptyTaxonomy) {
            try validate(taxonomy: ["", "  "], [assignment("essai", "Essais et documents")])
        }
    }

    @Test func anEmptyResponseThrowsRatherThanReturningAnEmptyMapping() {
        #expect(throws: ShelfMappingValidator.Failure.emptyResponse) {
            try validate([])
        }
    }

    /// The important half of "rejected rather than partially accepted": a response
    /// in which nothing survived must not come back as a valid, empty mapping — that
    /// would reach the user as "your library has no genres", which is a lie about the
    /// data rather than a report of a bad run.
    @Test func aResponseWhereNothingSurvivesThrowsRatherThanComingBackEmpty() {
        #expect(throws: ShelfMappingValidator.Failure.nothingUsable) {
            try validate([
                assignment("science-fiction", "Rayon imaginaire"),
                assignment("fantasy", "Rayon fantasy"),
                assignment("manga", "Rayon manga")
            ])
        }
    }

    @Test func aResponseOfNothingButBlanksThrows() {
        #expect(throws: ShelfMappingValidator.Failure.nothingUsable) {
            try validate([assignment("", ""), assignment("  ", "  ")])
        }
    }

    @Test func aResponseNamingOnlyGenresThatWereNeverOfferedThrows() {
        #expect(throws: ShelfMappingValidator.Failure.nothingUsable) {
            try validate(
                [assignment("manga", "Essais et documents")],
                genres: ["essai"]
            )
        }
    }
}
