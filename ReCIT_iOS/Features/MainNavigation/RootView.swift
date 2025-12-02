//
//  ContentView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/08/2025.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @ObservedObject var authModel: AuthModel

    @StateObject private var userModel: UserModel = .init()
    @StateObject private var listModel: ListModel = .init()
    @StateObject private var inventoryModel: InventoryModel = .init()

    @Environment(\.modelContext) var modelContext

    @State var isLoginSheetPresented: Bool = false

    var body: some View {
        MainTabView(authModel: authModel)
            .environmentObject(userModel)
            .environmentObject(listModel)
            .environmentObject(inventoryModel)
            .sheet(isPresented: $isLoginSheetPresented) {
                LoginView(authModel: authModel)
            }
            .onAppear {
                isLoginSheetPresented = !authModel.isAuthenticated
                refreshUserData()
            }
            .onChange(of: authModel.isAuthenticated) {
                isLoginSheetPresented = !authModel.isAuthenticated
                refreshUserData()
            }
            .refreshable {
                refreshUserData()
            }
    }

    func refreshUserData() {
        Task {
            if authModel.isAuthenticated {
                do {
                    try await userModel.syncUser(modelContext: modelContext)

                    if let myUser = userModel.myUser {
                        try await inventoryModel.syncItems(forUser: myUser, modelContext: modelContext)
                        try await listModel.syncLists(forUser: myUser, modelContext: modelContext)
                    }
                } catch {
                    print("⚠️⚠️⚠️⚠️⚠️ Error during user sync: \(error)")
                }
            }
        }
    }
}

//#Preview {
//    RootView()
//}
