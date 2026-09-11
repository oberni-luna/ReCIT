//
//  RootView+RefreshUserData.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 17/01/2026.
//

import Foundation

extension RootView {
    func refreshUserData() {
        Task {
            guard authModel.isAuthenticated else { return }
            do {
                print("## Sync my user ")
                try await userModel.syncMyUser(modelContext: modelContext)
                print(" --> done \(userModel.myUser?.username ?? "<Empty>")")
            } catch {
                print("⚠️⚠️⚠️⚠️⚠️ Error during user sync: \(error)")
                // A session the server no longer honours is not a sync that failed: nothing
                // below can succeed either, so the tabs would keep their first-sync
                // placeholders for ever with nothing to tap — the shape of issue 0068. Drop
                // the session and `RootView` shows the authentication flow on the next render.
                if SessionExpiry.isSessionGone(error) {
                    await authModel.logout()
                }
                return
            }

            guard let myUser = userModel.myUser else { return }
            inventoryModel.start(entityModel: entityModel, errorReporter: errorReporter)
            // Accepting an invitation pulls the new friend's books on the spot, which is the
            // one thing `UserModel` needs the inventory for.
            userModel.start(inventoryModel: inventoryModel)
            transactionModel.start(userModel: userModel, inventoryModel: inventoryModel, errorReporter: errorReporter)

            // Shelves must sync BEFORE inventory so items can resolve their shelf
            // membership into the Shelf ⇄ InventoryItem relation. See ADR 0003.
            do {
                try await shelfModel.syncShelves(forUser: myUser, modelContext: modelContext)
            } catch {
                print("⚠️⚠️⚠️⚠️⚠️ Error during shelves sync: \(error)")
            }

            // My inventory is gated per-user via `User.lastInventorySync`, not the
            // SyncStatusStore, so it syncs outside the domain tracking below.
            do {
                try await inventoryModel.syncInventory(forUser: myUser, modelContext: modelContext)
            } catch {
                print("⚠️⚠️⚠️⚠️⚠️ Error during inventory sync: \(error)")
            }

            // Each domain drives its own first-sync marker so an unsynced screen
            // shows a placeholder, and one domain failing doesn't block the others.
            await sync(.community) {
                try await userModel.syncRelations(modelContext: modelContext)
                // Friends only: a stranger met in a transaction, or looked up in the reader
                // search, is in the store too, and syncing their inventory would be both a
                // request for nothing and a pile of books in the inventory search that nobody
                // can borrow.
                for user in userModel.friends(modelContext: modelContext) {
                    try await inventoryModel.syncInventory(forUser: user, modelContext: modelContext)
                }
            }

            await sync(.lists) {
                try await listModel.syncLists(forUser: myUser, modelContext: modelContext)
            }

            await sync(.transactions) {
                try await transactionModel.syncTransactions(modelContext: modelContext)
            }
        }
    }

    /// Runs one domain's sync while updating its `SyncStatusStore` phase, so a
    /// screen can tell "not synced yet" from "synced and empty".
    private func sync(
        _ domain: SyncStatusStore.Domain,
        _ operation: () async throws -> Void
    ) async {
        syncStatus.markStarted(domain)
        do {
            try await operation()
            syncStatus.markCompleted(domain)
        } catch {
            print("⚠️⚠️⚠️⚠️⚠️ Error during \(domain.rawValue) sync: \(error)")
            syncStatus.markFailed(domain)
        }
    }
}
