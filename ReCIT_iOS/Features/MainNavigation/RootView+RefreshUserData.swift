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
            if authModel.isAuthenticated {
                do {
                    print("## Sync my user ")
                    try await userModel.syncMyUser(modelContext: modelContext)
                    print(" --> done \(userModel.myUser?.username ?? "<Empty>")")

                    if let myUser = userModel.myUser {
                        transactionModel.start(userModel: userModel, inventoryModel: inventoryModel)

                        try await inventoryModel.syncInventory(forUser: myUser, modelContext: modelContext)

                        try await userModel.syncUserNetwork(modelContext: modelContext)

                        for user in userModel.getAllOtherUsers(modelContext: modelContext) {
                            try await inventoryModel.syncInventory(forUser: user, modelContext: modelContext)
                        }

                        try await listModel.syncLists(forUser: myUser, modelContext: modelContext)

                        try await transactionModel.syncTransactions(modelContext: modelContext)
                    }
                } catch {
                    print("⚠️⚠️⚠️⚠️⚠️ Error during user sync: \(error)")
                }
            }
        }
    }
}
