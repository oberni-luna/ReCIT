//
//  UITestHooks.swift
//  ReCIT_iOS
//
//  The two seams the end-to-end scenario needs in the app itself, and nothing else.
//
//  The scenario in `UITests/E2EScenarioTests.swift` drives the real app against the real
//  inventaire.io, so almost everything it does is ordinary tapping. Two things a simulator
//  cannot do on its own are the exception, and both are answered here:
//
//  1. **A camera.** `CodeScannerView` compiles to a placard on the simulator: a tap hands back
//     whatever string the view was built with. That string is a constant in the app, which
//     makes a scanning session a single book repeated. Here it becomes the scenario's own list
//     of ISBNs, walked one entry per book the session finishes with — added, unknown, or
//     already owned — so the second tap scans the second book.
//  2. **A guaranteed signed-out launch.** The session lives in the keychain, which survives an
//     uninstall by design (see `Keychain`). A run that started signed in from the last one
//     would skip the first step of the scenario and report it green.
//
//  **Everything here is inert unless the app was launched with `-uitest`, and the whole seam is
//  compiled out of Release.** A build a user can install has `isActive == false` and no way to
//  set it: the scanner reads its constant, and nothing is ever reset.
//
//  See `docs/features/0012-end-to-end-scenario.md`.
//

import Foundation
import Observation

@MainActor
@Observable
final class UITestHooks {
    static let shared: UITestHooks = .init()

    /// Turns every seam in this type on. Passed by the scenario, never by anything else.
    static let activationArgument: String = "-uitest"
    /// Asks for the signed-out launch. Separate from activation so a scenario can opt out of
    /// the wipe — resuming a half-finished run by hand, say — without losing the camera.
    static let resetArgument: String = "-uitest-reset"
    /// The barcodes the placard hands out, in order, comma separated.
    static let barcodesVariable: String = "E2E_SCAN_CODES"

    /// Whether the app is under the scenario. False in Release, always.
    let isActive: Bool

    private let barcodes: [String]
    /// How far through the list the session has got. Observed, so the scanner's body is
    /// re-evaluated when it moves and the placard is rebuilt around the next barcode —
    /// `CodeScannerView.updateUIViewController` copies the fresh struct over the controller's.
    private var index: Int = 0

    private init() {
        let info: ProcessInfo = .processInfo
        #if DEBUG
        isActive = info.arguments.contains(Self.activationArgument)
        #else
        isActive = false
        #endif
        barcodes = (info.environment[Self.barcodesVariable] ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.isEmpty == false }
    }

    // MARK: - The camera

    /// What the next tap on the placard should read, or `nil` when the app is not under the
    /// scenario or the list is spent — in which case the scanner keeps its own constant.
    var currentBarcode: String? {
        guard isActive, barcodes.indices.contains(index) else { return nil }

        return barcodes[index]
    }

    /// Moves to the next barcode. Called when a book has been *finished with* rather than when
    /// one is seen: a barcode is read several times a second while it is in frame, and
    /// advancing per sighting would race through the list in one tap.
    func advanceBarcode() {
        guard isActive, index < barcodes.count else { return }

        index += 1
    }

    // MARK: - The launch

    /// Puts the app back to a first launch: no session, no cookies, no onboarding answer, no
    /// local store. Runs before anything reads any of them — see `ReCIT.init()`.
    ///
    /// The keychain is the reason this exists at all. Uninstalling the app between runs (which
    /// the runner script does) clears the container, the defaults and the SwiftData store, but
    /// not the session: `AuthService` restores it into the cookie jar from its keychain entry
    /// the moment it is built, and the scenario would open on a signed-in app.
    static func prepareLaunch() {
        #if DEBUG
        let info: ProcessInfo = .processInfo
        guard info.arguments.contains(activationArgument),
              info.arguments.contains(resetArgument)
        else { return }

        Keychain.delete(key: Env.production.keychainKey)
        Keychain.delete(key: Env.development.keychainKey)

        let jar: HTTPCookieStorage = .shared
        for cookie in jar.cookies ?? [] {
            jar.deleteCookie(cookie)
        }

        let defaults: UserDefaults = .standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("OnboardingStore.") || key.hasPrefix("SyncStatusStore.") {
            defaults.removeObject(forKey: key)
        }

        removeLocalStore()
        #endif
    }

    /// Deletes the SwiftData store, so a run never inherits the last one's books. Belt and
    /// braces beside the uninstall: a scenario run by hand from Xcode does not get one.
    private static func removeLocalStore() {
        let manager: FileManager = .default
        let directory: URL = .applicationSupportDirectory
        let names: [String] = ["default.store", "default.store-shm", "default.store-wal"]

        for name in names {
            try? manager.removeItem(at: directory.appending(path: name))
        }
    }
}
