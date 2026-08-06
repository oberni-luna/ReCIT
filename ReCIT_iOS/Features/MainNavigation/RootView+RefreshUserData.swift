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
                return
            }

            guard let myUser = userModel.myUser else { return }
            inventoryModel.start(entityModel: entityModel, errorReporter: errorReporter)
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
                try await userModel.syncUserNetwork(modelContext: modelContext)
                for user in userModel.getAllOtherUsers(modelContext: modelContext) {
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
