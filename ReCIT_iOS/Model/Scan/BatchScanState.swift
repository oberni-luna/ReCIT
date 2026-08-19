//
//  BatchScanState.swift
//  ReCIT_iOS
//
//  What the batch scanner's overlay row is showing, if anything. Pure data: the camera and
//  the network live on the other side of `BatchScanStateMachine`.
//
//  Three of these states are outcomes the user cannot act on — `notFound` and `alreadyOwned`.
//  They still take the screen, and deliberately so: silence is indistinguishable from a
//  camera that failed to read, which sends the user back to re-aim at a book that will never
//  resolve. They are also what stops the next scan while they are up, so nothing may sit in
//  one of them indefinitely — see `BatchScanViewModel`'s notice hold. See PRD 0005.
//

import Foundation

enum BatchScanState: Equatable {
    /// Nothing recognised: the bare camera feed.
    case idle
    /// A barcode was accepted and the edition is being fetched.
    case lookingUp(code: String)
    /// inventaire has no edition behind this barcode. Routine rather than exceptional — it is
    /// an open, community-maintained database, and French or recent editions are often
    /// missing. A lookup that ran past its deadline lands here too: from where the user
    /// stands, an answer that never comes and an edition that does not exist are the same
    /// thing, and both are answered by pointing at the next book.
    case notFound(code: String)
    /// The edition came back and the user can file it.
    case resolved(book: ScannedBook)
    /// The edition came back and the user already has a copy. The row says so and refuses the
    /// add; a genuine second copy is still addable from the book screen. The match is on the
    /// resolved entity's *canonical* uri — see `BatchScanViewModel.isAlreadyOwned`.
    case alreadyOwned(book: ScannedBook)
    /// The item is being created on the server — the add waits, it is not optimistic.
    case adding(book: ScannedBook)
    /// The server confirmed. Held briefly as proof, then cleared.
    case added(book: ScannedBook)

    /// The book the row is about, once one is known.
    var book: ScannedBook? {
        switch self {
        case .idle, .lookingUp, .notFound:
            nil
        case .resolved(let book), .alreadyOwned(let book), .adding(let book), .added(let book):
            book
        }
    }

    /// Whether the overlay row is on screen at all.
    var showsRow: Bool {
        self != .idle
    }
}
