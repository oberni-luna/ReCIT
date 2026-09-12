//
//  BookAbsenceView.swift
//  ReCIT_iOS
//
//  The two ways the book screen can have no book to show, and the two different things it says.
//
//  They are one type rather than two blocks inlined in `BookDetailView`'s switch because they
//  are two readings of the same silence and have to stay told apart:
//
//  - **A work with nothing worth opening.** Either `reverse-claims` answers `[]` — a ghost
//    duplicate of *Americanah* is one, and the search returns it — or every edition it lists is
//    nameless, and the ladder refuses to redirect onto a book called `Unknown`. Nothing is
//    broken and nothing will fix itself, so there is no « Réessayer »: a button that can only
//    fail again is worse than no button.
//  - **A call that failed.** The book is presumably there and the network was not. This one
//    carries the way out, and it is the same « Réessayer » the search surface uses, because it
//    is the same gesture.
//
//  Before Move 3 neither screen was reachable and the one that existed was a bare
//  `Text("edition.no_result")` — "this edition does not exist on inventaire.io", which is about
//  the wrong entity for a work that simply has none. They are now ordinary outcomes of tapping a
//  search result, so they are `EmptyStateView` like every other absence in the app (issue 0073).
//
//  See PRD 0014.
//

import SwiftUI

struct BookAbsenceView: View {
    enum Absence: Equatable {
        /// There is no edition worth opening: inventaire.io lists none for this work, or lists
        /// only nameless ones. The two are one sentence on purpose — from the reader's side
        /// they are the same fact, and the copy is written to be true of both.
        case noEdition
        /// The resolution did not come back.
        case failed
    }

    let absence: Absence
    /// Sends the same resolution again. Only `.failed` offers it — see the type's note.
    var onRetry: (() -> Void)? = nil

    var body: some View {
        switch absence {
        case .noEdition:
            EmptyStateView(
                glyph: "books.vertical",
                title: "book.no_edition.title",
                message: "book.no_edition.message"
            )
            .accessibilityIdentifier("e2e.book.noEdition")

        case .failed:
            EmptyStateView(
                glyph: "wifi.slash",
                title: "book.resolve.error.title",
                message: "book.resolve.error.message",
                action: onRetry.map { .init(title: "inventory.search.error.retry", handler: $0) }
            )
            .accessibilityIdentifier("e2e.book.error")
        }
    }
}

#Preview("Aucune édition") {
    BookAbsenceView(absence: .noEdition)
}

#Preview("La connexion a échoué") {
    BookAbsenceView(absence: .failed) {}
}
