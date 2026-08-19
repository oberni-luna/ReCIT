//
//  BatchScanStateMachineTests.swift
//  ReCIT_iOSTests
//
//  The batch scanner's rules, driven by events instead of by a barcode in front of a lens.
//  Pure and network-free, like the shelf layout suite: no camera, no SwiftData, no SwiftUI.
//
//  The repeat-scan gate is the reason this suite exists. It is invisible in the UI until it
//  breaks, at which point the flow re-offers the book the user is still holding and is
//  unusable. Time is injected, so the cooldown is asserted rather than slept through.
//  See PRD 0005.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("BatchScanStateMachine")
struct BatchScanStateMachineTests {

    /// A hand-wound clock, so "two seconds later" costs nothing.
    private final class TestClock {
        var instant: Date = .init(timeIntervalSince1970: 0)

        func advance(by seconds: TimeInterval) {
            instant = instant.addingTimeInterval(seconds)
        }
    }

    private let cooldown: TimeInterval = 2
    private let firstCode: String = "9782367935836"
    private let secondCode: String = "9780007532766"

    private func makeMachine(clock: TestClock) -> BatchScanStateMachine {
        .init(cooldown: cooldown, now: { clock.instant })
    }

    private func book(_ code: String, title: String = "Le Nom du vent") -> ScannedBook {
        .init(
            uri: "inv:\(code)",
            title: title,
            authors: ["Patrick Rothfuss"],
            coverImageUrl: nil,
            code: code
        )
    }

    /// Scan, resolve, file, confirm, clear — the whole rhythm, so the gate tests can start
    /// from a book that has genuinely been handled.
    private func fileOneBook(_ code: String, in machine: inout BatchScanStateMachine) {
        machine.apply(.codeSeen(code))
        machine.apply(.lookupResolved(book(code)))
        machine.apply(.addStarted)
        machine.apply(.addFinished)
        machine.apply(.cleared)
    }

    // MARK: - Happy path

    @Test("A scan runs from the barcode to a filed book and gives the screen back")
    func happyPath() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)
        let scanned: ScannedBook = book(firstCode)

        #expect(machine.state == .idle)

        let seen: Bool = machine.apply(.codeSeen(firstCode))
        #expect(seen == true)
        #expect(machine.state == .lookingUp(code: firstCode))

        let resolved: Bool = machine.apply(.lookupResolved(scanned))
        #expect(resolved == true)
        #expect(machine.state == .resolved(book: scanned))

        let started: Bool = machine.apply(.addStarted)
        #expect(started == true)
        #expect(machine.state == .adding(book: scanned))

        let finished: Bool = machine.apply(.addFinished)
        #expect(finished == true)
        #expect(machine.state == .added(book: scanned))

        let cleared: Bool = machine.apply(.cleared)
        #expect(cleared == true)
        #expect(machine.state == .idle)
    }

    @Test("The resolved state carries the book the row draws")
    func resolvedStateCarriesTheBook() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)
        let scanned: ScannedBook = book(firstCode)

        machine.apply(.codeSeen(firstCode))
        machine.apply(.lookupResolved(scanned))

        #expect(machine.state.book == scanned)
        #expect(machine.state.showsRow == true)
    }

    // MARK: - One pending result at a time

    @Test("A second code arriving while one is pending is ignored")
    func secondCodeWhilePendingIsIgnored() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))

        // Still looking the first one up.
        let duringLookup: Bool = machine.apply(.codeSeen(secondCode))
        #expect(duringLookup == false)
        #expect(machine.state == .lookingUp(code: firstCode))

        // And still, once it is resolved and waiting for the user's tap.
        machine.apply(.lookupResolved(book(firstCode)))
        let whileOffered: Bool = machine.apply(.codeSeen(secondCode))
        #expect(whileOffered == false)
        #expect(machine.state == .resolved(book: book(firstCode)))
    }

    @Test("A lookup landing for a code the row is no longer waiting for is dropped")
    func staleLookupIsDropped() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))
        machine.apply(.cleared)

        let resolved: Bool = machine.apply(.lookupResolved(book(firstCode)))
        #expect(resolved == false)
        #expect(machine.state == .idle)
    }

    // MARK: - The repeat-scan gate

    @Test("The book still in front of the camera after being added is not offered again")
    func sameCodeIsIgnoredOnceHandled() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        fileOneBook(firstCode, in: &machine)

        // The camera is still pointed at it, frame after frame.
        clock.advance(by: 0.4)
        let firstSighting: Bool = machine.apply(.codeSeen(firstCode))
        #expect(firstSighting == false)

        clock.advance(by: 0.4)
        let secondSighting: Bool = machine.apply(.codeSeen(firstCode))
        #expect(secondSighting == false)
        #expect(machine.state == .idle)
    }

    @Test("A book held in frame stays gated however long it is held")
    func continuousSightingsKeepTheGateClosed() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        fileOneBook(firstCode, in: &machine)

        // Far past the cooldown in total, but never absent for a whole cooldown: a wobbling
        // camera must not count as the book having been put down.
        for _ in 0..<20 {
            clock.advance(by: cooldown * 0.5)
            let accepted: Bool = machine.apply(.codeSeen(firstCode))
            #expect(accepted == false)
        }
        #expect(machine.state == .idle)
    }

    @Test("Sightings during a pending row keep the gate closed after it clears")
    func sightingsWhilePendingKeepTheGateClosed() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))
        machine.apply(.lookupResolved(book(firstCode)))

        // The user takes their time before tapping; the book never leaves the frame.
        for _ in 0..<10 {
            clock.advance(by: cooldown * 0.5)
            let accepted: Bool = machine.apply(.codeSeen(firstCode))
            #expect(accepted == false)
        }

        machine.apply(.addStarted)
        machine.apply(.addFinished)
        machine.apply(.cleared)

        clock.advance(by: cooldown * 0.5)
        let afterClearing: Bool = machine.apply(.codeSeen(firstCode))
        #expect(afterClearing == false)
    }

    @Test("A different book is recognised immediately")
    func differentCodeIsAcceptedImmediately() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        fileOneBook(firstCode, in: &machine)

        clock.advance(by: 0.2)
        let accepted: Bool = machine.apply(.codeSeen(secondCode))
        #expect(accepted == true)
        #expect(machine.state == .lookingUp(code: secondCode))
    }

    @Test("The gate remembers one code, so the next book releases the previous one")
    func theGateHoldsASingleCode() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        fileOneBook(firstCode, in: &machine)

        clock.advance(by: 0.2)
        fileOneBook(secondCode, in: &machine)

        // The first book is no longer the one being kept out.
        clock.advance(by: 0.2)
        let accepted: Bool = machine.apply(.codeSeen(firstCode))
        #expect(accepted == true)
    }

    @Test("A book taken out of frame for the cooldown may be scanned again")
    func cooldownExpires() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        fileOneBook(firstCode, in: &machine)

        clock.advance(by: cooldown - 0.5)
        let stillGated: Bool = machine.apply(.codeSeen(firstCode))
        #expect(stillGated == false)

        // Put down, picked up again. The sighting above pushed the deadline back, so the
        // full cooldown has to pass from it.
        clock.advance(by: cooldown + 0.5)
        let accepted: Bool = machine.apply(.codeSeen(firstCode))
        #expect(accepted == true)
        #expect(machine.state == .lookingUp(code: firstCode))
    }

    @Test("An unresolvable code says so, and stays gated so it is not re-offered every frame")
    func lookupFailureCountsAsHandled() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))

        let failed: Bool = machine.apply(.lookupFailed(code: firstCode))
        #expect(failed == true)
        // The row stands and names the code: saying nothing would look exactly like a scan
        // the camera never made.
        #expect(machine.state == .notFound(code: firstCode))
        #expect(machine.state.showsRow == true)

        machine.apply(.cleared)

        clock.advance(by: 0.4)
        let rescanned: Bool = machine.apply(.codeSeen(firstCode))
        #expect(rescanned == false)
    }

    @Test("A book already in the inventory stays gated too")
    func alreadyOwnedCountsAsHandled() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)
        let scanned: ScannedBook = book(firstCode)

        machine.apply(.codeSeen(firstCode))

        let owned: Bool = machine.apply(.lookupResolvedAlreadyOwned(scanned))
        #expect(owned == true)
        #expect(machine.state == .alreadyOwned(book: scanned))
        // The row still carries the book, so it can be drawn and opened.
        #expect(machine.state.book == scanned)

        machine.apply(.cleared)

        clock.advance(by: 0.4)
        let rescanned: Bool = machine.apply(.codeSeen(firstCode))
        #expect(rescanned == false)
    }

    // MARK: - The lookup's deadline

    @Test("A lookup that runs past its deadline lands in the unknown-edition state")
    func timeoutLandsInNotFound() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))

        let timedOut: Bool = machine.apply(.lookupTimedOut(code: firstCode))
        #expect(timedOut == true)
        // The same row as an edition inventaire does not have: from where the user stands,
        // an answer that never comes and no answer at all are the same thing.
        #expect(machine.state == .notFound(code: firstCode))
    }

    @Test("A timed-out code is not re-offered while the book is still in frame")
    func timedOutCodeStaysGated() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))
        machine.apply(.lookupTimedOut(code: firstCode))
        machine.apply(.cleared)

        clock.advance(by: 0.4)
        let rescanned: Bool = machine.apply(.codeSeen(firstCode))
        #expect(rescanned == false)
    }

    @Test("A lookup landing after its own timeout is dropped")
    func lookupResolvingAfterTimeoutIsDropped() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))
        machine.apply(.lookupTimedOut(code: firstCode))

        // The abandoned request answers a minute later; the row has moved on.
        let resolved: Bool = machine.apply(.lookupResolved(book(firstCode)))
        #expect(resolved == false)
        #expect(machine.state == .notFound(code: firstCode))
    }

    @Test("A notice the user cannot act on still holds the screen against the next book")
    func noticeRowsBlockTheNextScan() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        machine.apply(.codeSeen(firstCode))
        machine.apply(.lookupFailed(code: firstCode))

        clock.advance(by: 0.4)
        let duringNotice: Bool = machine.apply(.codeSeen(secondCode))
        #expect(duringNotice == false)
        #expect(machine.state == .notFound(code: firstCode))

        // Which is why the row has to clear itself — see `BatchScanViewModel`'s notice hold.
        machine.apply(.cleared)
        let afterNotice: Bool = machine.apply(.codeSeen(secondCode))
        #expect(afterNotice == true)
        #expect(machine.state == .lookingUp(code: secondCode))
    }

    // MARK: - A failed add

    /// The other half of a failed add — telling the user — is the view model's, and lands on
    /// the snack bar; what the machine owes is a row that can be tapped again.
    @Test("A failed add leaves the book on screen and the action retryable")
    func failedAddIsRetryable() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)
        let scanned: ScannedBook = book(firstCode)

        machine.apply(.codeSeen(firstCode))
        machine.apply(.lookupResolved(scanned))
        machine.apply(.addStarted)

        let failed: Bool = machine.apply(.addFailed)
        #expect(failed == true)
        #expect(machine.state == .resolved(book: scanned))

        // And the user can simply tap again.
        let retried: Bool = machine.apply(.addStarted)
        #expect(retried == true)

        let finished: Bool = machine.apply(.addFinished)
        #expect(finished == true)
        #expect(machine.state == .added(book: scanned))
    }

    // MARK: - Out-of-order events

    @Test("Outcomes that do not match the current state are ignored")
    func outOfOrderEventsAreIgnored() {
        let clock: TestClock = .init()
        var machine: BatchScanStateMachine = makeMachine(clock: clock)

        let startedFromIdle: Bool = machine.apply(.addStarted)
        let finishedFromIdle: Bool = machine.apply(.addFinished)
        let failedFromIdle: Bool = machine.apply(.addFailed)
        let clearedFromIdle: Bool = machine.apply(.cleared)
        #expect(startedFromIdle == false)
        #expect(finishedFromIdle == false)
        #expect(failedFromIdle == false)
        #expect(clearedFromIdle == false)
        #expect(machine.state == .idle)

        let timedOutFromIdle: Bool = machine.apply(.lookupTimedOut(code: firstCode))
        #expect(timedOutFromIdle == false)
        #expect(machine.state == .idle)

        machine.apply(.codeSeen(firstCode))
        let startedWhileLookingUp: Bool = machine.apply(.addStarted)
        let finishedWhileLookingUp: Bool = machine.apply(.addFinished)
        #expect(startedWhileLookingUp == false)
        #expect(finishedWhileLookingUp == false)
        #expect(machine.state == .lookingUp(code: firstCode))

        // An outcome for a code the row is no longer waiting for is not one of its own.
        let ownedForAnotherCode: Bool = machine.apply(.lookupResolvedAlreadyOwned(book(secondCode)))
        #expect(ownedForAnotherCode == false)
        #expect(machine.state == .lookingUp(code: firstCode))
    }
}
