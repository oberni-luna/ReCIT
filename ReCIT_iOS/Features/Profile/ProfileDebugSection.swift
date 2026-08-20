//
//  ProfileDebugSection.swift
//  ReCIT_iOS
//
//  A way into the onboarding screens that does not require being a new user. Both of them
//  are, by design, almost impossible to reach twice: the accueil is a question asked once
//  per account, and the bilan only appears at the end of a scanning session that filed
//  books onto a library with no étagère. That is right for users and useless for testing.
//
//  It also splits a device problem. The scanner needs a camera, so it can only be tried on
//  a phone; the arrangement needs Apple Intelligence, so on a phone older than an iPhone 15
//  Pro it can only be tried in a simulator. One row each means neither half waits for the
//  other.
//
//  `#if DEBUG` on purpose: this is scaffolding, not a feature, and it must not reach a
//  Release build — which also means it is absent from TestFlight, where a Release
//  configuration is what gets archived.
//
//  The rows are deliberately not translated and not styled like the rest of the screen.
//  They should look like what they are.
//

#if DEBUG

import SwiftUI
import SwiftData

struct ProfileDebugSection: View {
    @Binding var path: NavigationPath

    @Environment(AutoSortModel.self) private var autoSortModel
    @Environment(OnboardingStore.self) private var onboarding
    @Environment(UserModel.self) private var userModel

    /// Every book the store holds, filtered in Swift rather than in the predicate:
    /// SwiftData cannot express an empty to-many, which is the same reason
    /// `AutoSortModel` and the bilan's illustration read the inventory this way.
    @Query private var allItems: [InventoryItem]

    @State private var isPresentingWelcome: Bool = false
    @State private var isPresentingTally: Bool = false
    @State private var isScanning: Bool = false
    /// Set when the accueil is dismissed through its call to action, so the scanner opens
    /// only then — a cover cannot be raised from inside the one that is leaving.
    @State private var scanWasChosen: Bool = false

    /// What the bilan would report. The real one carries the count of the session that just
    /// ran; standing in for it with the books that are actually unshelved keeps the screen
    /// honest, and makes the covers it paints the user's own.
    private var unshelvedCount: Int {
        allItems.filter(\.shelves.isEmpty).count
    }

    /// The user's own books, which is what the accueil's condition counts — the same filter
    /// `OnboardingWelcomeModifier` applies, so the state reported here is the state that
    /// decides.
    private var ownedBookCount: Int {
        guard let ownerId: String = userModel.myUser?._id else { return 0 }

        return allItems.filter { $0.ownerId == ownerId }.count
    }

    /// Whether the accueil would present itself right now, asked of the same rule the app
    /// asks. Shown next to the button that forgets the answer, because forgetting it is only
    /// half of the condition: an inventory holding books suppresses the accueil regardless,
    /// and without this line the button would look broken every time it did nothing.
    private var welcomeWouldShow: Bool {
        guard let user: User = userModel.myUser else { return false }

        return OnboardingGate.presentsWelcome(
            inventoryHasSynced: user.lastInventorySync != nil,
            ownedBookCount: onboarding.forcesWelcome ? 0 : ownedBookCount,
            welcomeAnswered: onboarding.hasAnsweredWelcome(userId: user._id)
        )
    }

    private var autoSortEntryPoint: AutoSortEntryPoint {
        .init(availability: autoSortModel.availability)
    }

    var body: some View {
        Section("Debug") {
            Button("Ouvrir l'onboarding scan") {
                isPresentingWelcome = true
            }
            .foregroundStyle(.foregroundTinted)

            Button("Ouvrir l'onboarding auto-sort") {
                isPresentingTally = true
            }
            .foregroundStyle(.foregroundTinted)

            // The accueil in situ: presented by the gate rather than by a button, which is
            // the one path the two rows above cannot exercise. Its binding is derived, so
            // this takes effect at once where the conditions hold — not at the next launch.
            Button("Rejouer l'accueil en situation") {
                guard let userId: String = userModel.myUser?._id else { return }

                onboarding.resetWelcome(userId: userId)
                // The empty-inventory clause is stood in for rather than reproduced: the
                // real thing would mean deleting the tester's books off inventaire.io.
                onboarding.forcesWelcome = true
            }
            .foregroundStyle(.foregroundTinted)

            Text(stateLine)
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
        }
        // The accueil, then the scanner it leads to, so the chain can be walked on a device
        // exactly as a new user would walk it — including the real bilan at the end of the
        // session, which the scanner owns and this section does not fake.
        .fullScreenCover(isPresented: $isPresentingWelcome, onDismiss: openScannerIfChosen) {
            OnboardingWelcomeView(
                onScan: {
                    scanWasChosen = true
                    isPresentingWelcome = false
                },
                onLater: { isPresentingWelcome = false }
            )
        }
        .fullScreenCover(isPresented: $isScanning) {
            BatchScanView()
        }
        // The bilan on its own, standing in for the end of a session. Its CTA pushes onto
        // this screen's path rather than the session's, which is the one thing here that is
        // not the real wiring — the destination is the same.
        .fullScreenCover(isPresented: $isPresentingTally) {
            OnboardingScanTallyView(
                addedBookCount: unshelvedCount,
                entryPoint: autoSortEntryPoint,
                onSort: {
                    isPresentingTally = false
                    path.append(NavigationDestination.autoSort)
                },
                onLater: { isPresentingTally = false }
            )
        }
    }

    /// Everything the two conditions depend on, in one line, so a row that does nothing can
    /// be told from a row that is broken.
    private var stateLine: String {
        let welcome: String
        if welcomeWouldShow {
            welcome = onboarding.forcesWelcome
                ? "l'accueil s'affiche (inventaire vide simulé)"
                : "l'accueil s'affiche"
        } else {
            welcome = "l'accueil ne s'affiche pas (\(ownedBookCount) livre(s) en inventaire)"
        }

        return "\(unshelvedCount) livre(s) sur aucune étagère · Apple Intelligence : \(availabilityLabel) · \(welcome)"
    }

    private var availabilityLabel: String {
        switch autoSortEntryPoint {
        case .offered: "disponible"
        case .hidden: "appareil non éligible"
        case .switchedOff: "désactivée"
        case .downloading: "téléchargement en cours"
        }
    }

    private func openScannerIfChosen() {
        guard scanWasChosen else { return }

        scanWasChosen = false
        isScanning = true
    }
}

#endif
