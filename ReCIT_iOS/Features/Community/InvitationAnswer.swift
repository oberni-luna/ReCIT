//
//  InvitationAnswer.swift
//  ReCIT_iOS
//
//  Answering an invitation, from either of the two screens that offer the answer: the
//  « Invitations » list and the reader's own profile.
//
//  It exists because the answer is the one gesture in the flow that leaves nothing behind. The
//  relation write is optimistic, so the row is gone from « Reçues » the instant it is tapped,
//  and the profile swaps its two buttons for a syncing inventory — there is no state left on
//  screen saying which of the two answers was given, or that anything was given at all. The
//  SnackBar is that sentence.
//
//  A refusal gets one too, in the same neutral voice as the button: turning an invitation down
//  is not an error, and it is the answer most worth confirming, since it leaves the emptiest
//  screen. Failures keep going through `AppErrorReporter` — the revert puts the row back, and
//  the snack bar in `MainTabView` says why.
//

import LBSnackBar
import SwiftData
import SwiftUI

@MainActor
struct InvitationAnswer {
    let userModel: UserModel
    let modelContext: ModelContext
    let snackBar: SnackBarAction

    func accept(_ user: User) {
        userModel.acceptRelation(with: user, modelContext: modelContext)
        show(String(localized: "network.invitation.accepted \(user.username)"))
    }

    func refuse(_ user: User) {
        userModel.discardRelation(with: user, modelContext: modelContext)
        show(String(localized: "network.invitation.refused \(user.username)"))
    }

    private func show(_ title: String) {
        snackBar.show {
            SnackBarView(title: title, onDismiss: nil)
        }
    }
}
