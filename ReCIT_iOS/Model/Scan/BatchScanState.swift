//
//  BatchScanState.swift
//  ReCIT_iOS
//
//  What the batch scanner's overlay row is showing, if anything. Pure data: the camera and
//  the network live on the other side of `BatchScanStateMachine`.
//
//  `alreadyOwned` is an outcome the user cannot act on. It still takes the screen, and
//  deliberately so: silence is indistinguishable from a camera that failed to read, which
//  sends the user back to re-aim at a book that will never resolve. It is also what stops the
//  next scan while it is up, so nothing may sit in it indefinitely — see
//  `BatchScanViewModel`'s notice hold.
//
//  `notFound` used to be the same kind of dead end and no longer is: an edition inventaire
//  does not have can be *created* from the row (issue 0090, PRD 0015), so the state carries an
//  action and stays until it is used. What replaces the notice hold is the state machine's one
//  eviction rule — a different barcode takes the row, the same one does not. See
//  `BatchScanStateMachine.isReplaceable(by:)`. See PRD 0005.
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
    /// thing, and both are answered by offering to create the book — or by pointing at the
    /// next one, which is what takes this row down.
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

    /// Whether the row waits for the user instead of taking itself down. True of every state
    /// that carries an action — the book to file, the unknown edition to create — and false of
    /// the ones that only report. Read by `BatchScanViewModel` to decide whether a notice gets
    /// a hold.
    var holdsUntilActedOn: Bool {
        switch self {
        case .resolved, .notFound, .adding:
            true
        case .idle, .lookingUp, .alreadyOwned, .added:
            false
        }
    }
}
