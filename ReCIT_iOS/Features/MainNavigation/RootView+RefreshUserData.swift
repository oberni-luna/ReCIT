//
//  RootView+RefreshUserData.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 17/01/2026.
//

import Foundation

extension RootView {
    /// Pulls everything of the signed-in reader's from inventaire.io, in `UserDataSync`'s order.
    /// A call while a sync runs does nothing: that sync already pulls everything.
    func refreshUserData() {
        Task {
            guard authModel.isAuthenticated, syncStatus.beginRefresh() else { return }
            defer { syncStatus.endRefresh() }
            await userDataSync.run(modelContext: modelContext)
        }
    }

    /// The sync, wired to the models this view owns.
    private var userDataSync: UserDataSync {
        .init(
            userModel: userModel,
            shelfModel: shelfModel,
            inventoryModel: inventoryModel,
            transactionModel: transactionModel,
            groupModel: groupModel,
            listModel: listModel,
            syncStatus: syncStatus,
            errorReporter: errorReporter,
            onSessionGone: { [authModel] in await authModel.logout() }
        )
    }
}
