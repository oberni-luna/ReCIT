//
//  ContentView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/08/2025.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject var authModel: AuthModel
    @StateObject var userModel: UserModel = .init()
    @StateObject var listModel: ListModel = .init()
    @StateObject var entityModel: EntityModel = .init()
    @StateObject var searchModel: SearchModel = .init()
    @StateObject var inventoryModel: InventoryModel = .init()
    @StateObject var transactionModel: TransactionModel = .init()

    @Environment(\.modelContext) var modelContext

    var body: some View {
        if !authModel.isAuthenticated {
            LoginView(authModel: authModel) {}
        } else {
            MainTabView(authModel: authModel)
                .environmentObject(userModel)
                .environmentObject(listModel)
                .environmentObject(entityModel)
                .environmentObject(searchModel)
                .environmentObject(inventoryModel)
                .environmentObject(authModel)
                .environmentObject(transactionModel)
                .refreshable {
                    refreshUserData()
                }
                .onAppear {
                    refreshUserData()
                }
        }
    }
}
