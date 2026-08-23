//
//  SortFlowView.swift
//  ReCIT_iOS
//
//  The flow that ends in a sorted library: scan, read the bilan, file the books. One modal,
//  one navigation stack, entered at either end — at the camera by onboarding and by the scan
//  buttons, straight at the sorting surface from the home and from settings (`start`).
//
//  It was `BatchScanView`, and it kept the role that file's header already described: the
//  frame of a session — the modal, the close control, the stack and the ending. What changed
//  is that the sorting surface is now part of the flow rather than a screen in a tab, so the
//  frame is named after the whole thing (PRD 0009).
//
//  **`.fullScreenCover`, never `.sheet`**: a sheet's drag-to-dismiss fights the sorting
//  surface's drag and drop, and a book picked up a little low would take the screen down with
//  it. The presentation itself is the caller's, but the flow is written on that assumption.
//
//  **Nothing goes back to the sorting surface's left.** Reached from the bilan it would
//  re-offer « Ranger mes livres » for work already done, so the surface hides the back button
//  and offers an explicit close instead. Closing **keeps the draft** — the session is
//  app-scoped, and a user who steps out has to find their work where they left it; the only
//  thing that throws work away is the discard control, which asks first.
//
//  **No pull-to-refresh anywhere in the flow**, and that is a matter of *where the cover is
//  presented from*. `RootView` puts a `.refreshable` on the app, which every descendant
//  `ScrollView` picks up through the environment — so the shelves grid and the books carousel
//  both grew a spinner and swallowed vertical drags, on a screen whose one gesture is a drag.
//  `EnvironmentValues.refresh` is read-only, so it cannot be cleared from the inside: the flow
//  is presented from **outside** that modifier instead (see `RootView`).
//
//  A scanning *session*, presented modally. The camera stays up and books accumulate — point at
//  a barcode, the book rises over the live feed, one tap files it, the camera is already waiting
//  for the next one — and when the session ends it reports what it did before letting go.
//
//  It replaces the single-shot scan outright — read one code, dismiss, push the book screen.
//  That flow's one virtue, looking a book up, survives as the row's tappable text.
//
//  **Closing is two-stage, and closing is not leaving.** The close control ends the session; what
//  happens next is `OnboardingGate`'s answer. A session that added books to an inventory with no
//  étagère owes the user the bilan, so the camera is torn down, the bilan takes the same modal,
//  and dismissing *that* is what returns the user to wherever the session was opened from. A
//  session that added nothing, or a user who already has an étagère, leaves straight away and
//  never sees it. This is worth knowing before touching the close button: it used to hand control
//  back, and it no longer does.
//
//  The bilan replaces the camera inside this cover rather than stacking a second one over it.
//  Stacking would leave a capture session running behind a full-screen summary, holding the lens
//  and the battery to draw nothing, and would give the user two things to dismiss to get out of
//  one.
//
//  This view is therefore the session's frame and nothing else: it owns the modal, the close
//  control, the navigation stack and the ending. The working screen is `BatchScanCameraView`, and
//  the tally the ending reports comes from `BatchScanStateMachine` by way of the view model —
//  never counted here.
//
//  It carries its own `NavigationStack` because it is presented modally: that is what gives it a
//  close control, and what lets both halves push — the book screen from a pending row, the
//  auto-sort review from the bilan — without the camera or the summary being torn down under
//  them.
//
//  See PRD 0005 and PRD 0007.
//

import SwiftUI
import SwiftData

struct SortFlowView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(AutoSortModel.self) private var autoSortModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Where the flow opens. `.scanning` walks the whole way — camera, bilan, then the
    /// surface; `.sorting` puts the surface at the root, for a user who came to file books and
    /// not to scan them.
    var start: SortFlowStart = .scanning

    @State private var viewModel: BatchScanViewModel = .init()
    @State private var path: NavigationPath = .init()

    /// Set once, by the session ending, and never unset: the bilan is the last thing this modal
    /// shows. Going back to the camera from it would restart a session the user has just been
    /// told the results of.
    @State private var showsTally: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if start == .sorting {
                    ManualSortView(onClose: leave)
                } else if showsTally {
                    OnboardingScanTallyView(
                        addedBookCount: viewModel.addedBookCount,
                        // Derived here rather than inside the bilan, and inside this branch
                        // rather than beside the state: the bilan decides nothing, and reading
                        // availability during the session's own body is what keeps its ending
                        // live — `AutoSortModel.availability` reads an observable
                        // `SystemLanguageModel`, so a user who leaves the reason behind,
                        // switches Apple Intelligence on and comes back finds the offer with no
                        // relaunch. Read from here, the camera never depends on it.
                        entryPoint: .init(availability: autoSortModel.availability),
                        onSort: sortBooks,
                        onLater: leave
                    )
                    // Withdrawn on the bilan, which is one decision doing two jobs. It matches
                    // the accueil, which is a bare cover with no bar at all — the two screens are
                    // the same screen twice and must not sit a bar's height apart — and it takes
                    // the close control away with it, which is right: the bilan answers itself,
                    // and a third control in the bar would be a way out of a screen that already
                    // offers two.
                    .toolbar(.hidden, for: .navigationBar)
                } else {
                    BatchScanCameraView(viewModel: viewModel, onOpenBook: openBook)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                // The camera's way out. The sorting surface carries its own close control, so
                // offering this one alongside it made two crosses in one bar, one of which
                // ended a scanning session that was not running.
                if start == .scanning {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("action.close", systemImage: "xmark", action: endSession)
                            .tint(ScanOverlayPalette.ink)
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            // The surface, pushed from the bilan. A route local to this flow rather than a
            // case of the app-wide enum: nothing outside this modal can reach it, and the
            // enum gets smaller as the flow gets richer.
            .navigationDestination(for: SortFlowRoute.self) { route in
                switch route {
                case .sorting:
                    ManualSortView(onClose: leave)
                }
            }
        }
        // The drag session's own badges — the « + » that appears over a drop target — are drawn
        // by the system in the accent colour. A cover does not inherit the app's tint, so the
        // badge came out in the system green rather than ours.
        .tint(.foregroundTinted)
    }

    /// Pushes the book screen. The pending row is deliberately left standing, so coming back
    /// lands on the same book with its action still ready.
    private func openBook(_ book: ScannedBook) {
        guard book.uri.isEmpty == false else { return }
        path.append(NavigationDestination.book(anchor: .edition(uri: book.uri)))
    }

    /// Ends the scanning session — which is not the same as leaving it. Whether the user owes
    /// themselves a look at what just happened is the gate's decision, from the session's own
    /// tally and the étagères the user already has; nothing about it is decided here.
    private func endSession() {
        viewModel.cancelPending()

        guard OnboardingGate.presentsScanTally(
            sessionAddedBookCount: viewModel.addedBookCount,
            ownedShelfCount: viewModel.ownedShelfCount(
                userModel: userModel,
                modelContext: modelContext
            )
        ) else {
            leave()
            return
        }

        showsTally = true
    }

    /// Pushes the sorting surface onto the flow's own stack rather than dismissing and
    /// re-presenting: it syncs the library on arrival, and a modal closing under it would cost
    /// the user that wait twice. There is no way back from it — see the header.
    private func sortBooks() {
        path.append(SortFlowRoute.sorting)
    }

    private func leave() {
        dismiss()
    }
}
