//
//  SortFlowPresentation.swift
//  ReCIT_iOS
//
//  Whether the sorting flow is on screen. App-scoped, because "there is a sorting flow open"
//  is a fact about the app and not about whichever row was tapped to open it.
//
//  **One presentation point, four entry points.** The home's empty-shelf card, the étagères
//  screen, the settings row and its debug twin all used to append a case onto their tab's
//  navigation path; they now raise this flag and `MainTabView` presents the cover. Four local
//  `@State` flags would mean the same screen presented from two tabs, and two of them could
//  raise it at once.
//
//  The scan buttons keep presenting the flow themselves, with `start: .scanning`: they are
//  already local presentations that work, and moving them here would buy nothing — the flow
//  they open ends in the same surface either way.
//
//  See PRD 0009.
//

import Foundation

@MainActor
@Observable
final class SortFlowPresentation {

    /// Whether the flow's cover is up.
    var isPresented: Bool = false

    /// Opens the flow on the sorting surface. Idempotent: a second call while it is already up
    /// changes nothing, which is what makes two entry points harmless.
    func presentSorting() {
        isPresented = true
    }
}
