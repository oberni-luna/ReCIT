//
//  SortFlowPresentation.swift
//  ReCIT_iOS
//
//  Whether the sorting flow is on screen. App-scoped, because "there is a sorting flow open"
//  is a fact about the app and not about whichever row was tapped to open it.
//
//  **One presentation point, every entry point.** The sorting entries (the étagères toolbar, the
//  empty-shelf card, the settings row and its debug twin) used to append a case onto their tab's
//  navigation path; the scanning entries each presented their own cover. Both now raise this
//  flag, and `RootView` presents the cover — which matters for more than tidiness:
//
//  - two local flags in two tabs can raise the same screen twice over one app-scoped session;
//  - and a cover presented from inside a tab sits **under** the app's `.refreshable`, so every
//    `ScrollView` in the flow inherits a refresh action and steals the downward drags this
//    screen is built on. `EnvironmentValues.refresh` is read-only, so the only cure is to
//    present the flow from above that modifier.
//
//  See PRD 0009.
//

import Foundation

@MainActor
@Observable
final class SortFlowPresentation {

    /// Whether the flow's cover is up.
    var isPresented: Bool = false

    /// Where the flow opens. Only read while it is being presented.
    private(set) var start: SortFlowStart = .sorting

    /// Opens the flow on the sorting surface. Idempotent: a second call while it is already up
    /// changes nothing, which is what makes two entry points harmless.
    func presentSorting() {
        present(.sorting)
    }

    /// Opens the flow at the camera: scan, then the bilan, then the surface.
    func presentScanning() {
        present(.scanning)
    }

    private func present(_ start: SortFlowStart) {
        guard isPresented == false else { return }
        self.start = start
        isPresented = true
    }
}
