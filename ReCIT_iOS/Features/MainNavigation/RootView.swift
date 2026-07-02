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
    @State var userModel: UserModel
    @State var listModel: ListModel
    @State var entityModel: EntityModel
    @State var searchModel: SearchModel
    @State var inventoryModel: InventoryModel
    @State var transactionModel: TransactionModel

    @Environment(\.modelContext) var modelContext

    /// Composition root: a single `APIService` is shared by every app model so
    /// dependencies are wired in one place and a mock can be injected for tests.
    init(apiService: APIServicing = APIService(env: .production)) {
        _userModel = State(initialValue: UserModel(apiService: apiService))
        _listModel = State(initialValue: ListModel(apiService: apiService))
        _entityModel = State(initialValue: EntityModel(apiService: apiService))
        _searchModel = State(initialValue: SearchModel(apiService: apiService))
        _inventoryModel = State(initialValue: InventoryModel(apiService: apiService))
        _transactionModel = State(initialValue: TransactionModel(apiService: apiService))
    }

    var body: some View {
        if !authModel.isAuthenticated {
            LoginView(authModel: authModel) {}
        } else {
            MainTabView(authModel: authModel)
                .environment(userModel)
                .environment(listModel)
                .environment(entityModel)
                .environment(searchModel)
                .environment(inventoryModel)
                .environment(transactionModel)
                .environmentObject(authModel)
                .refreshable {
                    refreshUserData()
                }
                .onAppear {
                    refreshUserData()
                }
        }
    }
}
