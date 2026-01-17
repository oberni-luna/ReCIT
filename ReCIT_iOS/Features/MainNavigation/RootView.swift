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
    @StateObject var entityModel: EntityModel = .init()

    @Environment(\.modelContext) var modelContext

    @State var isLoginSheetPresented: Bool = false

    var body: some View {
        MainTabView(authModel: authModel)
            .environmentObject(userModel)
            .environmentObject(listModel)
            .environmentObject(inventoryModel)
            .environmentObject(authModel)
            .environmentObject(entityModel)
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

    
}

//#Preview {
//    RootView()
//}
