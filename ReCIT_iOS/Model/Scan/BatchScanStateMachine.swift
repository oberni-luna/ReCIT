//
//  BatchScanStateMachine.swift
//  ReCIT_iOS
//
//  The batch scanner's whole decision layer: which scans count, what the row shows, and when
//  the camera gets the screen back. Pure — no SwiftUI, no SwiftData, no camera package — so
//  the rules can be driven by events in a test instead of by a barcode in front of a lens.
//
//  Two rules carry the feature, and neither is visible in the design:
//
//  1. **One pending result at a time, unless the reader points at another book.** A second
//     barcode drifting through the frame must not replace what is on the row — except when
//     the row holds an *offer* (a book to file, an unknown edition to create), which the next
//     book is allowed to withdraw. Otherwise answering the offer would be the only way to keep
//     scanning. See `isReplaceable(by:)`.
//  2. **The repeat-scan gate.** `CodeScannerView` fires for as long as a barcode stays in
//     frame, so the book just added is still in frame a frame later. The machine remembers
//     the code it last accepted and refuses it until either a *different* code is seen (one
//     memory slot, so a new book simply evicts the old one) or the code has been out of frame
//     for `cooldown`. Every sighting pushes that deadline back, so a camera wobbling off the
//     book and back does not count as the book having gone away. Without this the flow
//     re-offers the book the user is still holding, forever. An outcome the user cannot act
//     on — an unknown edition, a lookup that timed out, a book already in the inventory —
//     counts as handled just as much as a filed book does, which is why the gate closes when
//     the code is *accepted* rather than when it is added.
//
//  It also keeps the session's tally, which is what the bilan at the end of a session reports.
//  The count belongs here rather than to the view model because this is the one type that
//  already knows which add events are real: no snapshot of the store can tell three books added
//  from three hundred already there, and a counter kept alongside the machine would be free to
//  drift from what the machine actually accepted.
//
//  See PRD 0005 and PRD 0007.
//

import Foundation

struct BatchScanStateMachine {
    /// How long a handled code must stay out of frame before it may be scanned again. Long
    /// enough to outlast the camera's scan interval and a shaky hand, short enough that
    /// deliberately re-scanning a book is not a waiting game.
    static let defaultCooldown: TimeInterval = 2

    private(set) var state: BatchScanState = .idle

    /// How many books this session has filed. Only a completed add counts: a lookup that
    /// failed, a book already owned, a barcode the gate refused and an add the server rejected
    /// all leave it where it was, so the number the bilan reports is the number of books that
    /// genuinely landed. It is never reset — a machine's lifetime *is* the session's.
    private(set) var addedBookCount: Int = 0

    /// The code most recently accepted, and when it was last seen in frame. One slot: a
    /// different code taking it is exactly what "ignored until a different code is seen" means.
    private var gatedCode: String?
    private var gatedCodeLastSeen: Date = .distantPast

    private let cooldown: TimeInterval
    /// Injected so the cooldown can be tested without sleeping.
    private let now: () -> Date

    init(
        cooldown: TimeInterval = BatchScanStateMachine.defaultCooldown,
        now: @escaping () -> Date = Date.init
    ) {
        self.cooldown = cooldown
        self.now = now
    }

    /// Applies an event. Returns `false` when the event was ignored — a repeat scan, a code
    /// arriving while another result is pending, or an outcome that no longer matches the
    /// state it was started from (a lookup landing after the row was cleared, say).
    @discardableResult
    mutating func apply(_ event: BatchScanEvent) -> Bool {
        switch event {
        case .codeSeen(let code):
            return accept(code: code)

        case .lookupResolved(let book):
            guard case .lookingUp(let pending) = state, pending == book.code else { return false }
            state = .resolved(book: book)
            return true

        case .lookupResolvedAlreadyOwned(let book):
            guard case .lookingUp(let pending) = state, pending == book.code else { return false }
            state = .alreadyOwned(book: book)
            return true

        case .lookupFailed(let code), .lookupTimedOut(let code):
            guard case .lookingUp(let pending) = state, pending == code else { return false }
            // The row says so rather than stepping aside: silence would look exactly like a
            // camera that failed to read, and the user would keep re-aiming at a book that
            // cannot resolve. The code stays gated either way — a book that cannot be
            // resolved is still handled, and must not be re-offered while it sits in view.
            state = .notFound(code: code)
            return true

        case .addStarted:
            guard case .resolved(let book) = state else { return false }
            state = .adding(book: book)
            return true

        case .addFinished:
            guard case .adding(let book) = state else { return false }
            state = .added(book: book)
            // The one place the tally moves. The add waits for the server, so this event only
            // ever arrives for a book inventaire has acknowledged.
            addedBookCount += 1
            return true

        case .addFailed:
            // Back to the offer rather than off the screen: the user can tap again. The add
            // waits for the server precisely so a failure is visible while the book is still
            // in hand.
            guard case .adding(let book) = state else { return false }
            state = .resolved(book: book)
            return true

        case .creationFinished(let book):
            // Only from the row that offered the creation, and only for the book it was about:
            // a sheet left open while the row was evicted by another barcode must not confirm
            // over whatever took its place.
            guard case .notFound(let pending) = state, pending == book.code else { return false }
            state = .added(book: book)
            // A created book is filed like any other, so the bilan counts it like any other.
            addedBookCount += 1
            return true

        case .cleared:
            guard state != .idle else { return false }
            state = .idle
            return true
        }
    }

    // MARK: - The gate

    private mutating func accept(code: String) -> Bool {
        let timestamp: Date = now()

        guard isReplaceable(by: code) else {
            // Nothing may start while a result is pending — but a code still in frame keeps
            // its place in the gate, or it would be re-offered the instant the row clears.
            if gatedCode == code { gatedCodeLastSeen = timestamp }
            return false
        }

        if gatedCode == code {
            guard timestamp.timeIntervalSince(gatedCodeLastSeen) >= cooldown else {
                gatedCodeLastSeen = timestamp
                return false
            }
        }

        gatedCode = code
        gatedCodeLastSeen = timestamp
        state = .lookingUp(code: code)
        return true
    }

    /// Whether the row may be given away to `code`.
    ///
    /// Two states are offers, and an offer must be refusable: `.notFound`, which proposes
    /// creating the book on inventaire.io, and `.resolved`, which proposes filing it. Neither
    /// takes itself down — one has no timer at all, the other waits for a tap — so without an
    /// eviction the reader is *obliged* to answer before the next book can be scanned: obliged
    /// to create a book they did not want to create, obliged to add a book they already have
    /// on another shelf, or obliged to leave the flow.
    ///
    /// A **different** barcode is exactly the way to say « not this one ». The **same** one,
    /// still in frame, is not: that is what the repeat-scan gate exists to refuse, and it keeps
    /// refusing it here.
    ///
    /// `.adding` is never replaceable — the write is already on its way to the server. Nor is
    /// `.lookingUp`, whose answer is seconds away, nor the two rows that clear themselves.
    private func isReplaceable(by code: String) -> Bool {
        switch state {
        case .idle:
            true
        case .notFound(let pending):
            pending != code
        case .resolved(let book):
            book.code != code
        case .lookingUp, .alreadyOwned, .adding, .added:
            false
        }
    }
}
