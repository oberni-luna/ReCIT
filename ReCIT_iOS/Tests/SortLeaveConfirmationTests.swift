//
//  SortLeaveConfirmationTests.swift
//  ReCIT_iOSTests
//
//  The close control of « Ranger mes livres » asks before leaving unsaved changes behind,
//  until the user has once answered « Quitter ». What can be got wrong is asking when there is
//  nothing to say, or asking again once answered.
//

import Testing
@testable import ReCIT_iOS

@Suite struct SortLeaveConfirmationTests {

    @Test func asksWhenChangesAreUnsaved() {
        #expect(SortLeaveConfirmation.isNeeded(hasPendingChanges: true, isApplying: false, isAcknowledged: false))
    }

    @Test func leavesAtOnceWithNothingUnsaved() {
        #expect(SortLeaveConfirmation.isNeeded(hasPendingChanges: false, isApplying: false, isAcknowledged: false) == false)
    }

    @Test func neverAsksAgainOnceAcknowledged() {
        #expect(SortLeaveConfirmation.isNeeded(hasPendingChanges: true, isApplying: false, isAcknowledged: true) == false)
    }

    /// A run in flight carries on without the screen: leaving then loses nothing.
    @Test func leavesAtOnceWhileARunIsWriting() {
        #expect(SortLeaveConfirmation.isNeeded(hasPendingChanges: true, isApplying: true, isAcknowledged: false) == false)
    }
}
