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
    @State var shelfModel: ShelfModel
    @State var transactionModel: TransactionModel
    @State var genreEnrichmentModel: GenreEnrichmentModel
    @State var errorReporter: AppErrorReporter
    @State var syncStatus: SyncStatusStore

    @Environment(\.modelContext) var modelContext

    /// Composition root: a single `APIService` is shared by every app model so
    /// dependencies are wired in one place and a mock can be injected for tests.
    init(apiService: APIServicing = APIService(env: .production)) {
        let errorReporter: AppErrorReporter = .init()
        _errorReporter = State(initialValue: errorReporter)
        _userModel = State(initialValue: UserModel(apiService: apiService))
        _listModel = State(initialValue: ListModel(apiService: apiService, errorReporter: errorReporter))
        let entityModel: EntityModel = .init(apiService: apiService)
        _entityModel = State(initialValue: entityModel)
        _searchModel = State(initialValue: SearchModel(apiService: apiService))
        _inventoryModel = State(initialValue: InventoryModel(apiService: apiService, errorReporter: errorReporter))
        _shelfModel = State(initialValue: ShelfModel(apiService: apiService, errorReporter: errorReporter))
        _transactionModel = State(initialValue: TransactionModel(apiService: apiService, errorReporter: errorReporter))
        _genreEnrichmentModel = State(initialValue: GenreEnrichmentModel(apiService: apiService, entityModel: entityModel, errorReporter: errorReporter))
        _syncStatus = State(initialValue: SyncStatusStore())
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
                .environment(shelfModel)
                .environment(transactionModel)
                .environment(genreEnrichmentModel)
                .environment(errorReporter)
                .environment(syncStatus)
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
