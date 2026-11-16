//
//  AppEnvironment.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// Everything the app's screens read from the environment: every shared model, the router, the
/// sync, the store and the tint. Built by `RootView`, which owns the models, and applied twice:
/// to the app, and to the sheet an Ex-libris link opens over a modal, which UIKit presents with an
/// empty environment (issue 143). One modifier, so a model added later reaches both.
///
/// The SnackBar needs nothing here: it draws in a window of its own, from anywhere.
struct AppEnvironment: ViewModifier {
    let authModel: AuthModel
    let router: TabRouter
    let userModel: UserModel
    let listModel: ListModel
    let entityModel: EntityModel
    let editionDuplicatesModel: EditionDuplicatesModel
    let searchModel: SearchModel
    let inventoryModel: InventoryModel
    let shelfModel: ShelfModel
    let transactionModel: TransactionModel
    let groupModel: GroupModel
    let entityCreationModel: EntityCreationModel
    let genreEnrichmentModel: GenreEnrichmentModel
    let autoSortModel: AutoSortModel
    let sortSessionModel: SortSessionModel
    let sortFlowPresentation: SortFlowPresentation
    let errorReporter: AppErrorReporter
    let syncStatus: SyncStatusStore
    let onboardingStore: OnboardingStore
    let tipsStore: TipsStore
    let recentSearchStore: RecentSearchStore
    let donationModel: DonationModel
    let syncUserData: SyncUserDataAction
    let modelContext: ModelContext

    func body(content: Content) -> some View {
        content
            .environment(userModel)
            .environment(listModel)
            .environment(entityModel)
            .environment(editionDuplicatesModel)
            .environment(searchModel)
            .environment(inventoryModel)
            .environment(shelfModel)
            .environment(transactionModel)
            .environment(groupModel)
            .environment(entityCreationModel)
            .environment(genreEnrichmentModel)
            .environment(autoSortModel)
            .environment(sortSessionModel)
            .environment(sortFlowPresentation)
            .environment(errorReporter)
            .environment(syncStatus)
            .environment(onboardingStore)
            .environment(tipsStore)
            .environment(recentSearchStore)
            .environment(donationModel)
            .environment(authModel)
            .environment(router)
            // The same sync pull-to-refresh runs, for a screen with nothing to pull: « Tout »'s
            // « Réessayer ».
            .environment(\.syncUserData, syncUserData)
            .modelContext(modelContext)
            .tint(.foregroundTinted)
    }
}
