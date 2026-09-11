//
//  AccountDeletionSummary.swift
//  ReCIT_iOS
//
//  What deleting the account costs, counted before it is spent.
//
//  The four numbers are the four things `DELETE /api/user` destroys on the server: the items,
//  the shelves, the listings, and the transactions it cancels on the way. They are counted from
//  SwiftData — the local copy is what the screen has under its hand, and asking the server for
//  a fresher count would put a spinner in front of a warning.
//
//  A pure type, with no SwiftUI and no networking in it, so the two rules that matter can be
//  tested without a screen: a line is only drawn for something there actually is, and a loan in
//  progress is said out loud rather than left as one number among four — it is the only one of
//  the four that also happens to somebody else.
//

import Foundation

struct AccountDeletionSummary: Equatable {

    /// What is being counted. The order of the cases is the order the screen reads them in:
    /// books first because that is what a library is, transactions last because that is the
    /// line that leads into the sentence about other people.
    enum Kind: String, CaseIterable {
        case books
        case shelves
        case lists
        case activeTransactions
    }

    struct Line: Equatable, Identifiable {
        let kind: Kind
        let count: Int

        var id: String { kind.rawValue }
    }

    let books: Int
    let shelves: Int
    let lists: Int
    let activeTransactions: Int

    init(books: Int, shelves: Int, lists: Int, activeTransactions: Int) {
        self.books = books
        self.shelves = shelves
        self.lists = lists
        self.activeTransactions = activeTransactions
    }

    /// One line per thing there is something of, in `Kind` order.
    ///
    /// Zeroes are dropped rather than drawn as « 0 étagère »: a warning listing what the user
    /// does not have reads as boilerplate, and boilerplate is what gets skipped on the screen
    /// where skipping is expensive.
    var lines: [Line] {
        Kind.allCases.compactMap { kind in
            let count: Int = count(for: kind)
            return count > 0 ? .init(kind: kind, count: count) : nil
        }
    }

    /// Nothing to lose — a fresh account, or one whose inventory never synced. The screen then
    /// says what will happen instead of listing what will go.
    var isEmpty: Bool {
        lines.isEmpty
    }

    /// Whether the extra sentence about other people is owed.
    var warnsAboutActiveTransactions: Bool {
        activeTransactions > 0
    }

    private func count(for kind: Kind) -> Int {
        switch kind {
        case .books: books
        case .shelves: shelves
        case .lists: lists
        case .activeTransactions: activeTransactions
        }
    }
}
