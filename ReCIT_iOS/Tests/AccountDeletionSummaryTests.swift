//
//  AccountDeletionSummaryTests.swift
//  ReCIT_iOSTests
//

import Testing
@testable import ReCIT_iOS

@Suite("AccountDeletionSummary")
struct AccountDeletionSummaryTests {

    @Test("Lines come in reading order: books, shelves, lists, transactions")
    func linesAreInReadingOrder() {
        let summary: AccountDeletionSummary = .init(books: 115, shelves: 4, lists: 2, activeTransactions: 1)

        #expect(summary.lines.map(\.kind) == [.books, .shelves, .lists, .activeTransactions])
        #expect(summary.lines.map(\.count) == [115, 4, 2, 1])
    }

    @Test("Nothing is drawn for something there is none of")
    func zeroesAreDropped() {
        let summary: AccountDeletionSummary = .init(books: 12, shelves: 0, lists: 0, activeTransactions: 3)

        #expect(summary.lines.map(\.kind) == [.books, .activeTransactions])
        #expect(summary.isEmpty == false)
    }

    @Test("An account with nothing in it has no lines at all")
    func emptyAccount() {
        let summary: AccountDeletionSummary = .init(books: 0, shelves: 0, lists: 0, activeTransactions: 0)

        #expect(summary.lines.isEmpty)
        #expect(summary.isEmpty)
        #expect(summary.warnsAboutActiveTransactions == false)
    }

    @Test("The sentence about other people is owed exactly when a transaction is in progress")
    func transactionWarning() {
        #expect(AccountDeletionSummary(books: 1, shelves: 1, lists: 1, activeTransactions: 1).warnsAboutActiveTransactions)
        #expect(AccountDeletionSummary(books: 9, shelves: 9, lists: 9, activeTransactions: 0).warnsAboutActiveTransactions == false)
    }

    /// The line identity is what `ForEach` keys on: two renders of the same kind must be the
    /// same row, or a changing count would animate as a row being replaced.
    @Test("A line's id is its kind, not its count")
    func lineIdentityIsStable() {
        let before: AccountDeletionSummary = .init(books: 3, shelves: 0, lists: 0, activeTransactions: 0)
        let after: AccountDeletionSummary = .init(books: 4, shelves: 0, lists: 0, activeTransactions: 0)

        #expect(before.lines.map(\.id) == after.lines.map(\.id))
    }
}
