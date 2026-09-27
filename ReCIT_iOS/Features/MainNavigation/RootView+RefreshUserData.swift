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
            // Accepting an invitation pulls the new friend's books, and the étagères they
            // share, on the spot — which is the one thing `UserModel` needs either of these
            // two for.
            userModel.start(inventoryModel: inventoryModel, shelfModel: shelfModel)
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
            //
            // The community domain is the relations and nothing more: it used to wait for every
            // friend's books as well, so the Profil kept its friends behind a spinner until the
            // last inventory had landed. The friends now show as soon as they are known, and
            // their books follow below, each cell carrying its own bar.
            await sync(.community) {
                try await userModel.syncRelations(modelContext: modelContext)
            }

            // After the relations, which fetch the members of my groups along with my friends
            // (`network`): most of the names the groups need are in the store by then.
            do {
                try await groupModel.syncMyGroups(myUserId: myUser._id, modelContext: modelContext)
            } catch {
                print("⚠️⚠️⚠️⚠️⚠️ Error during groups sync: \(error)")
            }

            await sync(.lists) {
                try await listModel.syncLists(forUser: myUser, modelContext: modelContext)
            }

            await sync(.transactions) {
                try await transactionModel.syncTransactions(modelContext: modelContext)
            }

            await syncFriendsInventories()
        }
    }

    /// Friends' étagères and books, one friend at a time — last, because each is the longest
    /// sync of the launch and none of them is what the screen in front of the user waits for.
    /// One at a time, so each bar fills in turn rather than all of them crawling together.
    ///
    /// Friends only: a stranger met in a transaction, or looked up in the reader search, is in
    /// the store too, and syncing their inventory would be both a request for nothing and a
    /// pile of books in the inventory search that nobody can borrow.
    private func syncFriendsInventories() async {
        // In the Profil's order, the never-synced first: they are the cells with a bar, and a
        // friend already synced only has a refresh to wait for.
        let friends: [User] = userModel.friends(modelContext: modelContext)
            .sorted { $0.username.localizedStandardCompare($1.username) == .orderedAscending }
        let queue: [User] = friends.filter { $0.lastInventorySync == nil } + friends.filter { $0.lastInventorySync != nil }
        for user in queue {
            // Their étagères first, for the same reason mine are: an item resolves its shelf
            // membership against `Shelf` objects that must already exist. The server decides
            // what a friend shares — `by-owners` answers with exactly the shelves it will let
            // me see — so nothing is filtered here.
            //
            // Caught per friend: a friend whose shelves or books fail is not a reason to stop
            // pulling anyone else's. Their cell goes back to waiting, and the next refresh
            // tries again.
            do {
                try await shelfModel.syncShelves(forUser: user, modelContext: modelContext)
            } catch {
                print("⚠️⚠️⚠️⚠️⚠️ Error during shelves sync for \(user.username): \(error)")
            }
            do {
                try await inventoryModel.syncInventory(forUser: user, modelContext: modelContext)
            } catch {
                print("⚠️⚠️⚠️⚠️⚠️ Error during inventory sync for \(user.username): \(error)")
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
