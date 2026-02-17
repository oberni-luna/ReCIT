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
    @StateObject var inventoryModel: InventoryModel = .init()
    @StateObject var transactionModel: TransactionModel = .init()

    @Environment(\.modelContext) var modelContext

    var body: some View {
        if userModel.myUser == nil {
            LoginView(authModel: authModel) {
                refreshUserData()
            }
        } else {
            MainTabView(authModel: authModel)
                .environmentObject(userModel)
                .environmentObject(listModel)
                .environmentObject(inventoryModel)
                .environmentObject(authModel)
                .environmentObject(transactionModel)
                .onAppear {
                    refreshUserData()
                }
                .onChange(of: authModel.isAuthenticated) {
                    refreshUserData()
                }
                .refreshable {
                    refreshUserData()
                }
        }
    }

    
}

//#Preview {
//    RootView()
//}
