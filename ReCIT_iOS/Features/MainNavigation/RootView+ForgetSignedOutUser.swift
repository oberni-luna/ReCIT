//
//  RootView+ForgetSignedOutUser.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 27/09/2026.
//

import Foundation

extension RootView {
    /// Leaves nothing of the last account on this device once there is no session.
    ///
    /// **Here, and keyed on `isAuthenticated`, rather than in the sign-out button.** There are
    /// three ways to lose the session — the sign-out row, a sync that meets a session the
    /// server no longer honours, a launch whose keychain holds none — and the button only ever
    /// saw the first. The other two left a whole account's friends, lists and étagères in the
    /// store, for the next person to sign in to find under their own name. `RootView` is the
    /// one place that sees every one of them, because it is the one that swaps the tabs for
    /// the welcome screen.
    ///
    /// **After a yield**, as the sign-out button used to: the tabs are still being torn down
    /// when the flag flips, and a view that renders a row being deleted under it crashes.
    ///
    /// What goes and what stays is `UserModel.wipeUserData`: every person's data, none of the
    /// books'. The first-sync markers go with them, or the next account's tabs would skip
    /// their placeholder and say « nothing here » before their first sync has even started;
    /// and so does any unsent draft of « Ranger mes livres », which names étagères that are
    /// no longer in the store. What each account was taught and searched for is keyed by its
    /// own id and stays — see `DeleteAccountView` for when it goes.
    func forgetSignedOutUser() async {
        await Task.yield()
        sortSessionModel.discardChanges()
        syncStatus.reset()
        groupModel.reset()
        do {
            try userModel.wipeUserData(modelContext: modelContext)
        } catch {
            print("⚠️⚠️⚠️⚠️⚠️ Error while wiping the signed-out user's data: \(error)")
        }
    }
}
