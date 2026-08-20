//
//  BatchScanView.swift
//  ReCIT_iOS
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

struct BatchScanView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: BatchScanViewModel = .init()
    @State private var path: NavigationPath = .init()

    /// Set once, by the session ending, and never unset: the bilan is the last thing this modal
    /// shows. Going back to the camera from it would restart a session the user has just been
    /// told the results of.
    @State private var showsTally: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if showsTally {
                    OnboardingScanTallyView(
                        addedBookCount: viewModel.addedBookCount,
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.close", systemImage: "xmark", action: endSession)
                        .tint(ScanOverlayPalette.ink)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
        }
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

    /// Pushes the auto-sort review onto the session's own stack rather than dismissing and
    /// re-presenting: the review screen generates its plan on arrival, and a modal closing under
    /// it would cost the user the wait twice. Cancelling it pops back to the bilan, which is
    /// still the screen they came from.
    private func sortBooks() {
        path.append(NavigationDestination.autoSort)
    }

    private func leave() {
        dismiss()
    }
}
