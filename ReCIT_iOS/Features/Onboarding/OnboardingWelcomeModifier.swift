//
//  OnboardingWelcomeModifier.swift
//  ReCIT_iOS
//
//  How the accueil reaches the screen: a full-screen cover over the app the tab host has already
//  built. That is what makes "Plus tard" a dismissal that reveals the inventory rather than a
//  screen transition — the bookshelf behind it, with its empty card and the note that now asks to
//  scan, is simply what was already there.
//
//  It gives the tab host a second responsibility beside its shared error observer, and that is the
//  accepted cost: the alternative, a third branch in the composition root beside the
//  unauthenticated one, would have to decide before the shared models are injected — which is
//  precisely when the user is not known yet.
//
//  The condition is `OnboardingGate`'s, not this view's: synced, empty, unanswered. The presented
//  binding is derived from it rather than latched into state, so answering the accueil dismisses
//  it as a consequence of the answer being stored — ADR 0001's first invariant, applied to a
//  presentation. Nothing here can drift out of step with the gate, because nothing here decides.
//
//  Waiting on the sync needs no placeholder of its own: `ShelvesView` already shows one while
//  `lastInventorySync` is nil, so the accueil lands after it, never over a screen that is still
//  filling in.
//
//  The scanner is raised on the way out rather than on top: a cover cannot be presented from
//  inside the one that is leaving, and stacking it over an accueil that is dismissing itself
//  (answering is what dismisses it) would tear the camera down with it. So the answer is recorded,
//  the accueil goes, and the session starts as the cover finishes closing.
//
//  See PRD 0007.
//

import SwiftData
import SwiftUI

extension View {
    /// Poses the first-launch accueil over this view when `user` is owed one.
    func onboardingWelcome(user: User?) -> some View {
        modifier(OnboardingWelcomeModifier(user: user))
    }
}

struct OnboardingWelcomeModifier: ViewModifier {
    let user: User?

    @Environment(OnboardingStore.self) private var onboarding
    /// The flow's one presentation point (PRD 0009): the accueil raises the flag and `RootView`
    /// opens the cover, above the app's `.refreshable` so the flow's scroll views keep their
    /// downward drags.
    @Environment(SortFlowPresentation.self) private var sortFlow

    /// The user's books, for the one thing the gate asks about them: whether there are any. Read
    /// from the store like the empty shelf's note is, so the two cannot disagree about it.
    @Query private var ownedBooks: [InventoryItem]

    /// Set by "Scanner mes livres" and spent once the accueil is off screen.
    @State private var opensScannerOnDismiss: Bool = false

    init(user: User?) {
        self.user = user

        let ownerId: String = user?._id ?? ""
        _ownedBooks = Query(filter: #Predicate { $0.ownerId == ownerId })
    }

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: presentsWelcome, onDismiss: openScannerIfChosen) {
                OnboardingWelcomeView(onScan: scanNow, onLater: answer)
            }
    }

    /// Presented while the gate says so; dismissed by the answer being recorded. The setter
    /// catches any other way out and treats it as an answer too — the accueil is asked once
    /// however it is left.
    private var presentsWelcome: Binding<Bool> {
        .init(
            get: {
                OnboardingGate.presentsWelcome(
                    inventoryHasSynced: user?.lastInventorySync != nil,
                    ownedBookCount: debugForcedBookCount ?? ownedBooks.count,
                    welcomeAnswered: hasAnsweredWelcome
                )
            },
            set: { isPresented in
                guard !isPresented else { return }

                answer()
            }
        )
    }

    /// Stands in for the book count when the debug section is forcing the accueil, so the
    /// gate is still the thing deciding — it is asked the same question with one input
    /// substituted, rather than bypassed. Always nil in a Release build.
    private var debugForcedBookCount: Int? {
        #if DEBUG
        onboarding.forcesWelcome ? 0 : nil
        #else
        nil
        #endif
    }

    private var hasAnsweredWelcome: Bool {
        guard let user else { return false }

        return onboarding.hasAnsweredWelcome(userId: user._id)
    }

    private func answer() {
        guard let user else { return }

        onboarding.markWelcomeAnswered(userId: user._id)
    }

    private func scanNow() {
        opensScannerOnDismiss = true
        answer()
    }

    private func openScannerIfChosen() {
        guard opensScannerOnDismiss else { return }

        opensScannerOnDismiss = false
        sortFlow.presentScanning()
    }
}
