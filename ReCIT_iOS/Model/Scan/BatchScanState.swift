//
//  BatchScanState.swift
//  ReCIT_iOS
//
//  What the batch scanner's overlay row is showing, if anything. Pure data: the camera and
//  the network live on the other side of `BatchScanStateMachine`.
//
//  The failure states of PRD 0005 — `notFound(code:)` and `alreadyOwned(book:)` — are cases
//  this enum is shaped to receive (issue 0019). They differ from the ones here only in what
//  the row draws and whether the action is offered, not in how the gate treats them.
//

import Foundation

enum BatchScanState: Equatable {
    /// Nothing recognised: the bare camera feed.
    case idle
    /// A barcode was accepted and the edition is being fetched.
    case lookingUp(code: String)
    /// The edition came back and the user can file it.
    case resolved(book: ScannedBook)
    /// The item is being created on the server — the add waits, it is not optimistic.
    case adding(book: ScannedBook)
    /// The server confirmed. Held briefly as proof, then cleared.
    case added(book: ScannedBook)

    /// The book the row is about, once one is known.
    var book: ScannedBook? {
        switch self {
        case .idle, .lookingUp:
            nil
        case .resolved(let book), .adding(let book), .added(let book):
            book
        }
    }

    /// Whether the overlay row is on screen at all.
    var showsRow: Bool {
        self != .idle
    }
}
