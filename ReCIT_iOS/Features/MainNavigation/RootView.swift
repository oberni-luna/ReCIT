//
//  ContentView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/08/2025.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AuthModel.self) var authModel
    @State var userModel: UserModel
    @State var listModel: ListModel
    @State var entityModel: EntityModel
    @State var searchModel: SearchModel
    @State var inventoryModel: InventoryModel
    @State var shelfModel: ShelfModel
    @State var transactionModel: TransactionModel
    @State var genreEnrichmentModel: GenreEnrichmentModel
    @State var autoSortModel: AutoSortModel
    @State var sortSessionModel: SortSessionModel
    /// Whether the sorting flow's cover is up. App-scoped so the four entry points raise one
    /// flag rather than four (PRD 0009).
    @State var sortFlowPresentation: SortFlowPresentation = .init()
    @State var errorReporter: AppErrorReporter
    @State var syncStatus: SyncStatusStore
    @State var onboardingStore: OnboardingStore
    /// What each account has been taught by doing it (PRD 0013). Built here like every other
    /// shared model, and injected below — the astuces belong to the person signed in, so the
    /// store has to outlive the screen that shows them.
    @State var tipsStore: TipsStore
    /// What each account has actually searched for (PRD 0012). Built here like every other
    /// shared model, and injected below — the history belongs to the person signed in, so it
    /// has to outlive the field that writes it.
    @State var recentSearchStore: RecentSearchStore
    /// The welcome screen's wall of covers (PRD 0011). Built here like every other model, and
    /// injected into the signed-out branch — it is the one model that runs before there is a
    /// user, so it is also the one that never reaches `MainTabView`.
    @State var coverWallModel: CoverWallModel

    @Environment(\.modelContext) var modelContext

    /// Composition root: a single `APIService` is shared by every app model so
    /// dependencies are wired in one place and a mock can be injected for tests.
    ///
    /// Two services rather than one, since issue 0068. `apiService` carries the session, the
    /// way everything that talks about a user has to. `publicAPIService` is for the calls made
    /// before there is a user — today, the cover wall's — and it goes through
    /// `URLSession.cookieless`: every public endpoint on inventaire.io answers with an
    /// *anonymous* session under the two names a real one uses, and the app has no use for one.
    init(
        apiService: APIServicing = APIService(env: .production),
        publicAPIService: APIServicing = APIService(env: .production, session: .cookieless)
    ) {
        let errorReporter: AppErrorReporter = .init()
        _errorReporter = State(initialValue: errorReporter)
        _userModel = State(initialValue: UserModel(apiService: apiService, errorReporter: errorReporter))
        _listModel = State(initialValue: ListModel(apiService: apiService, errorReporter: errorReporter))
        let entityModel: EntityModel = .init(apiService: apiService)
        _entityModel = State(initialValue: entityModel)
        _searchModel = State(initialValue: SearchModel(apiService: apiService))
        _inventoryModel = State(initialValue: InventoryModel(apiService: apiService, errorReporter: errorReporter))
        let shelfModel: ShelfModel = .init(apiService: apiService, errorReporter: errorReporter)
        _shelfModel = State(initialValue: shelfModel)
        _transactionModel = State(initialValue: TransactionModel(apiService: apiService, errorReporter: errorReporter))
        let genreEnrichmentModel: GenreEnrichmentModel = .init(apiService: apiService, entityModel: entityModel, errorReporter: errorReporter)
        _genreEnrichmentModel = State(initialValue: genreEnrichmentModel)
        _autoSortModel = State(
            initialValue: AutoSortModel(
                genreEnrichment: genreEnrichmentModel,
                errorReporter: errorReporter
            )
        )
        // App-scoped rather than owned by the sorting screen: the writes it will run
        // (PRD 0008) have to outlive the screen, and so does the draft the user built
        // by dragging — leaving mid-session and coming back must find the stack.
        _sortSessionModel = State(initialValue: SortSessionModel())
        _syncStatus = State(initialValue: SyncStatusStore())
        _onboardingStore = State(initialValue: OnboardingStore())
        _tipsStore = State(initialValue: TipsStore())
        _recentSearchStore = State(initialValue: RecentSearchStore())
        _coverWallModel = State(initialValue: CoverWallModel(apiService: publicAPIService))
    }

    /// The sorting flow's flag as a binding: a cover needs one, and an observable is not one.
    private var presentsSortFlow: Binding<Bool> {
        .init(
            get: { sortFlowPresentation.isPresented },
            set: { sortFlowPresentation.isPresented = $0 }
        )
    }

    var body: some View {
        if !authModel.isAuthenticated {
            // The signed-out branch owns its own navigation stack (PRD 0010): the welcome
            // screen is its root, so a logged-out launch opens on what the app is for rather
            // than on a form. Signing out lands back here for the same reason.
            AuthFlowView(authModel: authModel, coverWall: coverWallModel)
        } else {
            MainTabView(authModel: authModel)
                // **Innermost of the three, on purpose.** Pull-to-refresh belongs to the tabs
                // and to nothing else: an action set here reaches every `ScrollView` *inside*
                // `MainTabView`, and stops short of the cover declared above it. Applied
                // outside the cover it would reach the sorting flow's scroll views too, where a
                // downward drag is a book being filed and not a refresh — and
                // `EnvironmentValues.refresh` is read-only, so it cannot be cleared from within.
                .refreshable {
                    refreshUserData()
                }
                // The sorting flow: **above the refreshable, below the models.** Above, so the
                // flow's scroll views keep their downward drags; below, so its screens actually
                // find the models — a cover's content inherits what its ancestors inject, and a
                // cover attached outside the `.environment` calls sees none of them (which is a
                // crash, not a degradation).
                //
                // One presentation for every entry point (PRD 0009): the étagères toolbar, the
                // empty-shelf card, the settings row and its debug twin open it at the surface,
                // the scan buttons open it at the camera, all through one app-scoped flag.
                .fullScreenCover(isPresented: presentsSortFlow) {
                    SortFlowView(start: sortFlowPresentation.start)
                }
                .environment(userModel)
                .environment(listModel)
                .environment(entityModel)
                .environment(searchModel)
                .environment(inventoryModel)
                .environment(shelfModel)
                .environment(transactionModel)
                .environment(genreEnrichmentModel)
                .environment(autoSortModel)
                .environment(sortSessionModel)
                .environment(sortFlowPresentation)
                .environment(errorReporter)
                .environment(syncStatus)
                .environment(onboardingStore)
                .environment(tipsStore)
                .environment(recentSearchStore)
                .environment(authModel)
                .onAppear {
                    refreshUserData()
                }
        }
    }
}
