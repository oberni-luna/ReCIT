//
//  SortProposalTests.swift
//  ReCIT_iOSTests
//
//  What asking the model for a rangement puts on the stack — asserted without a store,
//  without a network and without the model, which is exactly why the conversion is a
//  value type over an `AutoSortPlan` and the sections the screen is showing.
//
//  The proposal is the one change generator the user did not operate by hand, so every
//  way it could betray them is a way the screen lies about their library: a shelf they
//  already have quietly duplicated, work they have just done offered to them again, a
//  new étagère appearing that will never be created.
//
//  Each test states an external behaviour — I asked for help, this is what appeared on
//  my screen. None reaches into how the conversion gets there.
//
//  See PRD 0008.
//

import Testing
@testable import ReCIT_iOS

@Suite("SortProposal")
struct SortProposalTests {

    private func book(_ id: String) -> AutoSortBook {
        .init(id: id, title: "Livre \(id)")
    }

    private func section(
        _ id: SortSection.ID,
        _ name: String?,
        _ books: [String]
    ) -> SortSection {
        .init(id: id, name: name, books: books.map(book))
    }

    /// A plan built by hand rather than through the pipeline: what is under test is the
    /// conversion, and a plan is a name and a set of books whatever produced it.
    private func plan(_ shelves: [(String, [String])]) -> AutoSortPlan {
        var mappings: [(String, String)] = []
        var books: [AutoSortBook] = []
        for (name, ids) in shelves {
            for id in ids {
                // One genre per book, named after the book, so the assignment is
                // unambiguous and the plan comes out exactly as declared here.
                mappings.append(("genre-\(id)", name))
                books.append(.init(id: id, title: "Livre \(id)", genres: ["genre-\(id)"]))
            }
        }
        guard let mapping = try? ShelfMappingValidator.validate(
            taxonomy: shelves.map(\.0),
            assignments: mappings.map { .init(genre: $0.0, shelfName: $0.1) },
            offeredGenres: mappings.map(\.0)
        ) else { return .init(nothingToPropose: books) }

        return .init(mapping: mapping, books: books)
    }

    /// The étagères a proposal was reconciled into, in the order it named them.
    private func destinations(_ proposal: SortProposal) -> [String: SortSection.ID] {
        var destinations: [String: SortSection.ID] = [:]
        for change in proposal.changes {
            guard case .moveBook(let bookId, _, let destination) = change else { continue }
            destinations[bookId] = destination
        }
        return destinations
    }

    private func createdNames(_ proposal: SortProposal) -> [String] {
        proposal.changes.compactMap { change in
            guard case .createShelf(_, let name) = change else { return nil }
            return name
        }
    }

    // MARK: - New étagères

    /// Proposed étagères that match nothing the user has become drafts — which is what
    /// makes them read « Nouvelle » on the surface — and every book the plan named lands
    /// in one.
    @Test func aProposalThatMatchesNothingBecomesDrafts() {
        let sections: [SortSection] = [
            section(.unshelved, nil, ["1", "2", "3"])
        ]
        let proposal: SortProposal = .init(
            plan: plan([("Romans policiers", ["1", "2"]), ("Poésie", ["3"])]),
            sections: sections
        )

        #expect(createdNames(proposal) == ["Romans policiers", "Poésie"])

        let writePlan: SortWritePlan = .init(
            snapshot: .init(books: [book("1"), book("2"), book("3")]),
            changes: proposal.changes
        )
        #expect(writePlan.summary.shelvesToCreate == 2)
        #expect(writePlan.summary.booksFiled == 3)
        #expect(writePlan.summary.booksLeftUnshelved == 0)
        #expect(writePlan.summary.droppedDrafts.isEmpty)
        for operation in writePlan.operations {
            #expect(writePlan.status(of: operation.section) == .new)
        }
    }

    /// A drafted étagère is filled by the same proposal that declared it: the books it
    /// names really do land in it, rather than in a section nobody declared.
    @Test func eachDraftedEtagereHoldsTheBooksItWasProposedFor() {
        let proposal: SortProposal = .init(
            plan: plan([("Romans policiers", ["1", "2"]), ("Poésie", ["3"])]),
            sections: [section(.unshelved, nil, ["1", "2", "3"])]
        )
        let projection: SortProjection = .init(
            snapshot: .init(books: [book("1"), book("2"), book("3")]),
            changes: proposal.changes
        )

        let named: [String: [String]] = .init(
            uniqueKeysWithValues: projection.sections
                .filter { $0.isUnshelved == false }
                .map { ($0.name ?? "", $0.books.map(\.id)) }
        )
        #expect(named["Romans policiers"] == ["1", "2"])
        #expect(named["Poésie"] == ["3"])
        #expect(projection.unshelved.books.isEmpty)
    }

    // MARK: - Reconciliation against étagères the user already has

    /// The user already has « Romans policiers ». A proposal naming it files books into
    /// it and creates nothing — asking for help must not duplicate a shelf that is right
    /// there on the screen.
    @Test func aProposalNamingAnEtagereTheUserHasFilesIntoItAndCreatesNothing() {
        let sections: [SortSection] = [
            section(.shelf("s1"), "Romans policiers", ["1"]),
            section(.unshelved, nil, ["2", "3"])
        ]
        let proposal: SortProposal = .init(
            plan: plan([("Romans policiers", ["2", "3"])]),
            sections: sections
        )

        #expect(createdNames(proposal).isEmpty)
        #expect(destinations(proposal) == ["2": .shelf("s1"), "3": .shelf("s1")])
    }

    /// « ROMANS POLICIERS », « romans policiers » and « Romans policiers » are one
    /// étagère to a reader, so they are one étagère here. A model that drops an accent or
    /// shouts a name must not thereby invent a second shelf.
    @Test func aProposedNameSpelledDifferentlyStillFilesIntoTheEtagereTheUserHas() {
        let sections: [SortSection] = [
            section(.shelf("s1"), "Poésie", ["1"]),
            section(.unshelved, nil, ["2"])
        ]
        let proposal: SortProposal = .init(
            plan: plan([("  POESIE ", ["2"])]),
            sections: sections
        )

        #expect(createdNames(proposal).isEmpty)
        #expect(destinations(proposal) == ["2": .shelf("s1")])
    }

    /// The user drafted « Romans policiers » two minutes ago and has not applied it. A
    /// proposal naming it fills that draft rather than making a second one of the same
    /// name — the duplicate `SortDraftNameRule` refuses by hand.
    @Test func aProposalNamingADraftAlreadyOnTheStackFilesIntoIt() {
        let sections: [SortSection] = [
            section(.draft("draft:abc"), "Romans policiers", ["1"]),
            section(.unshelved, nil, ["2"])
        ]
        let proposal: SortProposal = .init(
            plan: plan([("Romans policiers", ["2"])]),
            sections: sections
        )

        #expect(createdNames(proposal).isEmpty)
        #expect(destinations(proposal) == ["2": .draft("draft:abc")])
    }

    // MARK: - Asking again after sorting by hand

    /// Every book the proposal names is already where it proposes to put it, so nothing
    /// is pushed at all: asking again after sorting by hand cannot re-do work that is
    /// done, and the screen does not start claiming there is something to save.
    @Test func aProposalThatFilesBooksWhereTheyAlreadySitPushesNothing() {
        let sections: [SortSection] = [
            section(.shelf("s1"), "Romans policiers", ["1", "2"]),
            section(.unshelved, nil, [])
        ]
        let proposal: SortProposal = .init(
            plan: plan([("Romans policiers", ["1", "2"])]),
            sections: sections
        )

        #expect(proposal.isEmpty)
        #expect(proposal.changes.isEmpty)
    }

    /// One of the two books has since been filed by hand. Only the other one moves, and
    /// the étagère is not created twice.
    @Test func askingAgainOnlyMovesWhatIsStillLeftToFile() {
        let sections: [SortSection] = [
            section(.shelf("s1"), "Romans policiers", ["1"]),
            section(.unshelved, nil, ["2"])
        ]
        let proposal: SortProposal = .init(
            plan: plan([("Romans policiers", ["1", "2"])]),
            sections: sections
        )

        #expect(proposal.changes == [.moveBook(bookId: "2", from: .unshelved, to: .shelf("s1"))])
    }

    // MARK: - Nothing to propose

    /// A device that produced nothing leaves the stack exactly as it was — no drafts, no
    /// moves, and therefore no change to the buttons the user is looking at.
    @Test func aProposalThatProducedNothingLeavesTheStackUntouched() {
        let proposal: SortProposal = .init(
            plan: .init(nothingToPropose: [book("1"), book("2")]),
            sections: [section(.unshelved, nil, ["1", "2"])]
        )

        #expect(proposal.isEmpty)
    }

    /// A proposed étagère whose books the surface does not show — copies that left the
    /// inventory between the snapshot and the run — is not drafted at all. A shelf that
    /// appears marked « Nouvelle » only to be dropped for being empty is a shelf the user
    /// was promised and then denied.
    @Test func aProposedEtagereWithNoBookTheScreenShowsIsNotDrafted() {
        let proposal: SortProposal = .init(
            plan: plan([("Poésie", ["9"])]),
            sections: [section(.unshelved, nil, ["1"])]
        )

        #expect(proposal.isEmpty)
    }
}
