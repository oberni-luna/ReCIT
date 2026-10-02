//
//  SortLeaveConfirmation.swift
//  ReCIT_iOS
//
//  Whether the close control asks before leaving the sorting surface.
//
//  **It asks only when there is something unsaved, and only until it has been answered
//  « Quitter » once.** Closing keeps the draft — the session is app-scoped — so the question
//  is not "lose your work?" but "you know this is not saved yet?". Once the user has said yes
//  to that, they know, and asking again on every visit would be a toll on a gesture they have
//  understood. « Annuler » teaches nothing: the question comes back next time.
//
//  Never while a run is writing: the writes belong to the session and carry on without the
//  screen, so leaving then loses nothing, and what is pending is already on its way.
//
//  Pure by design — no store, no SwiftUI. The acknowledgement itself is kept by the view, per
//  device, in `AppStorage`.
//

import Foundation

enum SortLeaveConfirmation {
    static func isNeeded(
        hasPendingChanges: Bool,
        isApplying: Bool,
        isAcknowledged: Bool
    ) -> Bool {
        hasPendingChanges && isApplying == false && isAcknowledged == false
    }
}
