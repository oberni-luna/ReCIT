//
//  E2EDriver.swift
//  ReCIT_iOSUITests
//
//  The vocabulary the scenario is written in: a step, a wait, a tap, a drag — each one reporting
//  itself rather than asserting.
//
//  **Nothing here calls `XCTFail`.** A UI test normally stops at the first failure, which is
//  right when the answer wanted is "does this still work"; the answer wanted here is a
//  *compte-rendu*, and a run that stops at step 4 of 20 tells you nothing about the other
//  sixteen. So a step that throws is recorded KO with the reason, and the run carries on — up
//  to the point where carrying on would be theatre, which is what `critical` marks: the steps
//  after a failed critical one are recorded SKIP, honestly, instead of being attempted against
//  a screen that is not the one they were written for.
//
//  Every wait is explicit and bounded. There is no `sleep` in the scenario for its own sake:
//  the app talks to inventaire.io over the network, so the waits are long, but they are waits
//  *for something* and they say what when they run out.
//
//  **Two facts about iOS 26 shape half of this file.** Its floating tab bar and the buttons at
//  the foot of a full-screen cover report `isHittable == false` while sitting plainly on screen
//  and answering a finger, so `tap` falls back to tapping the centre of an element's frame
//  rather than waiting out a timeout on every one of them. And a tap on such a control is
//  sometimes simply swallowed — the accueil's « Plus tard » needs two about half the time — so
//  every tap that *changes screen* is written as `tap(_:until:)`: tap, look, tap again. Neither
//  is a workaround for a bug in the app; both are what driving this version of the platform
//  costs.
//
//  See `docs/features/0012-end-to-end-scenario.md`.
//

import Foundation
import XCTest

/// A step that could not do what it set out to do. The message is what lands in the report's
/// KO column, so it is written for someone reading the report, not for a stack trace.
struct E2EFailure: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}

@MainActor
final class E2EDriver {
    let app: XCUIApplication
    let report: E2EReport

    /// How long any single wait may run. Generous on purpose: every screen in this scenario is
    /// behind at least one round trip to inventaire.io, and a slow answer is not a failure.
    static let defaultTimeout: TimeInterval = 30
    /// The wait for a screen that syncs a whole library on arrival.
    static let syncTimeout: TimeInterval = 90

    /// Set when a critical step fails: everything after it is recorded SKIP.
    private(set) var isAborted: Bool = false

    init(app: XCUIApplication, report: E2EReport) {
        self.app = app
        self.report = report
    }

    // MARK: - Steps

    /// Runs one step and files its line in the report. The body returns the step's `detail` —
    /// what it actually acted on — because most of it is only known once the step has run: the
    /// title of the book that came back, the name the shelf ended up with.
    @discardableResult
    func step(
        _ title: String,
        critical: Bool = true,
        _ body: () throws -> String
    ) -> Bool {
        guard !isAborted else {
            report.record(
                title: title,
                detail: "",
                status: .skipped,
                message: "Étape non jouée : une étape critique précédente a échoué.",
                duration: 0,
                screenshot: nil
            )
            return false
        }

        let started: Date = .now
        do {
            let detail: String = try body()
            report.record(
                title: title,
                detail: detail,
                status: .ok,
                duration: Date.now.timeIntervalSince(started),
                screenshot: screenshot()
            )
            return true
        } catch {
            let stated: String = (error as? E2EFailure)?.message ?? "\(error)"
            // A crashed app fails every wait that follows for the same uninteresting reason, so
            // the first step to notice says what really happened and puts the app back on its
            // feet. The screenshot above already shows the home screen, which is the proof.
            let crashed: Bool = app.state != .runningForeground
            let message: String = crashed
                ? stated + " L'application ne tournait plus : elle a planté pendant cette étape."
                : stated

            report.record(
                title: title,
                detail: "",
                status: .ko,
                message: message,
                duration: Date.now.timeIntervalSince(started),
                screenshot: screenshot()
            )

            if crashed { relaunchAfterCrash() }
            if critical { isAborted = true }
            return false
        }
    }

    /// Puts the app back after a crash, **without** the signed-out wipe: the session lives in
    /// the keychain, so relaunching this way lands where the crash happened rather than on the
    /// welcome screen, and the steps that were still to come can be attempted for real.
    private func relaunchAfterCrash() {
        app.launchArguments.removeAll { $0 == UITestHooksArguments.reset }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: E2EDriver.defaultTimeout)
        holds({ self.app.tabBars.firstMatch.exists }, within: E2EDriver.syncTimeout)
    }

    /// The screen as it stands, for the report and for the `.xcresult`.
    private func screenshot() -> Data {
        let shot: XCUIScreenshot = XCUIScreen.main.screenshot()
        let attachment: XCTAttachment = .init(screenshot: shot)
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "screenshot") { $0.add(attachment) }
        return shot.pngRepresentation
    }

    // MARK: - Finding

    /// Any element carrying this accessibility identifier, whatever its type. The scenario asks
    /// for identifiers rather than labels wherever one exists: a label is a translation, and a
    /// test that breaks when a word is reworded is a test nobody keeps.
    func any(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Every element carrying this identifier, in tree order.
    func all(_ identifier: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: identifier)
    }

    func exists(_ identifier: String) -> Bool {
        any(identifier).exists
    }

    /// The **text field** carrying this identifier. Asked for by type rather than by
    /// `any(_:)`, because a field drawn with a label beside it puts two elements under one
    /// identifier and the label is the one that resolves first — typing into it fails the
    /// whole run rather than the step.
    func textField(_ identifier: String) -> XCUIElement {
        app.textFields.matching(identifier: identifier).firstMatch
    }

    // MARK: - Waiting

    @discardableResult
    func waitFor(
        _ element: XCUIElement,
        _ what: String,
        timeout: TimeInterval = E2EDriver.defaultTimeout
    ) throws -> XCUIElement {
        guard element.waitForExistence(timeout: timeout) else {
            throw E2EFailure("\(what) n'est pas apparu au bout de \(Int(timeout)) s.")
        }
        return element
    }

    @discardableResult
    func waitForIdentifier(
        _ identifier: String,
        _ what: String,
        timeout: TimeInterval = E2EDriver.defaultTimeout
    ) throws -> XCUIElement {
        try waitFor(any(identifier), what, timeout: timeout)
    }

    /// Waits for a condition to hold, polling. Used where the thing to wait on is an absence or
    /// a count rather than an element — a row that has to clear, a carousel that has to shrink.
    func waitUntil(
        _ what: String,
        timeout: TimeInterval = E2EDriver.defaultTimeout,
        _ condition: () -> Bool
    ) throws {
        guard holds(condition, within: timeout) else {
            throw E2EFailure("\(what) n'est pas arrivé au bout de \(Int(timeout)) s.")
        }
    }

    /// Whether a condition comes true inside `timeout`. The non-throwing half of `waitUntil`,
    /// for the places that want to *ask* rather than to fail.
    @discardableResult
    func holds(_ condition: () -> Bool, within timeout: TimeInterval) -> Bool {
        let deadline: Date = .now.addingTimeInterval(timeout)
        repeat {
            if condition() { return true }
            _ = app.wait(for: .runningForeground, timeout: 0.3)
        } while Date.now < deadline
        return false
    }

    // MARK: - Acting

    func tap(
        _ identifier: String,
        _ what: String,
        timeout: TimeInterval = E2EDriver.defaultTimeout
    ) throws {
        let element: XCUIElement = try waitForIdentifier(identifier, what, timeout: timeout)
        try tap(element, what, timeout: timeout)
    }

    /// Taps, and falls back to tapping the centre of the element's frame when the framework
    /// keeps reporting it un-hittable.
    ///
    /// **The fallback is routine, not exceptional** — see the note at the top of the file.
    /// Waiting the full timeout on every such control would add minutes to the run for nothing,
    /// so an element that has *existed* for `hittableGrace` without becoming hittable is tapped
    /// by coordinate.
    func tap(
        _ element: XCUIElement,
        _ what: String,
        timeout: TimeInterval = E2EDriver.defaultTimeout
    ) throws {
        let hittableGrace: TimeInterval = 1.5
        let deadline: Date = .now.addingTimeInterval(timeout)
        var firstSeen: Date?

        while Date.now < deadline {
            if isReachable(element) {
                if element.isHittable {
                    element.tap()
                    return
                }

                let seen: Date = firstSeen ?? .now
                firstSeen = seen
                if Date.now.timeIntervalSince(seen) > hittableGrace {
                    tapAbsolute(element)
                    return
                }
            }
            _ = app.wait(for: .runningForeground, timeout: 0.3)
        }

        throw E2EFailure(
            element.exists
                ? "\(what) est hors de l'écran, impossible de le toucher."
                : "\(what) est introuvable, impossible de le toucher."
        )
    }

    /// Taps until the screen actually changes.
    ///
    /// Every tap that leaves the screen it was made on goes through this. A single tap on a
    /// cover's answer, or on a tab, is sometimes swallowed on iOS 26, and a scenario that takes
    /// the first tap on faith fails three steps later, somewhere that says nothing about what
    /// went wrong.
    ///
    /// `settle` is generous because it costs nothing when the tap worked: the condition is
    /// polled, so a screen that arrives in 200 ms is not waited on. It is only spent on taps
    /// that really did nothing — and on this app most screens are behind a round trip, so a
    /// short settle would retap a push that was simply still loading.
    func tap(
        _ element: XCUIElement,
        _ what: String,
        until condition: () -> Bool,
        attempts: Int = 3,
        settle: TimeInterval = 12
    ) throws {
        guard element.waitForExistence(timeout: E2EDriver.defaultTimeout) else {
            throw E2EFailure("\(what) est introuvable.")
        }

        for _ in 0..<attempts {
            if condition() { return }

            if isReachable(element) {
                if element.isHittable {
                    element.tap()
                } else {
                    tapAbsolute(element)
                }
            }

            if holds(condition, within: settle) { return }
        }

        throw E2EFailure(
            isReachable(element)
                ? "\(what) a été touché \(attempts) fois, sans effet visible à l'écran."
                : "\(what) est resté hors de l'écran, impossible de le toucher."
        )
    }

    /// Whether an element is somewhere a finger could actually land.
    ///
    /// **Asking `isHittable` about an element that is off screen does not answer `false` — it
    /// fails the test outright**, with "Activation point invalid and no suggested hit points
    /// based on element frame", and takes the whole run with it. The étagères carousel is where
    /// this bites: the second card sits three quarters past the right edge, exists, and cannot
    /// be asked about. So nothing here reads `isHittable` before this has said yes.
    func isReachable(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }

        let frame: CGRect = element.frame
        guard frame.width > 1, frame.height > 1 else { return false }

        return app.frame.contains(.init(x: frame.midX, y: frame.midY))
    }

    /// Taps the centre of an element's frame, in screen coordinates.
    func tapAbsolute(_ element: XCUIElement) {
        let frame: CGRect = element.frame
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(.init(dx: frame.midX, dy: frame.midY))
            .tap()
    }

    /// Clears a text field and types into it. Written as one operation because a field left with
    /// its previous contents is the single most common way a search step "passes" while looking
    /// for the wrong thing.
    func type(_ text: String, into field: XCUIElement, _ what: String) throws {
        guard field.waitForExistence(timeout: E2EDriver.defaultTimeout) else {
            throw E2EFailure("\(what) est introuvable.")
        }

        // Typing into something that is not a field raises inside XCTest and takes the whole
        // run with it, which is exactly what this scenario must never do: the report is worth
        // more than the step. Refuse it here and let the step be KO on its own.
        let typeable: [XCUIElement.ElementType] = [
            .textField, .secureTextField, .searchField, .textView
        ]
        guard typeable.contains(field.elementType) else {
            throw E2EFailure(
                "\(what) n'est pas une zone de saisie (\(field.elementType.rawValue)) — "
                + "l'identifiant désigne probablement le libellé plutôt que le champ."
            )
        }

        try tap(field, what)

        if let current = field.value as? String,
           current.isEmpty == false,
           current != field.placeholderValue {
            // A search field carries its own clear button; anything else is emptied one
            // character at a time, which is slow but never leaves half of the last query
            // behind — and a query half-replaced is a step that passes while searching for
            // the wrong thing.
            let clear: XCUIElement = field.buttons.firstMatch
            if isReachable(clear), clear.isHittable {
                clear.tap()
            } else {
                field.typeText(
                    .init(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
                )
            }
        }

        field.typeText(text)
    }

    /// One book onto one étagère. A SwiftUI `draggable` needs a long press before the lift and a
    /// pause before the release, which is what the two durations are: a plain swipe is read as a
    /// scroll and the book never leaves the carousel.
    func drag(_ source: XCUIElement, to target: XCUIElement) {
        let from: XCUICoordinate = source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.35))
        let to: XCUICoordinate = target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))

        from.press(
            forDuration: 1.2,
            thenDragTo: to,
            withVelocity: .slow,
            thenHoldForDuration: 1.2
        )
    }

    // MARK: - Navigation

    /// The four tabs the scenario visits.
    ///
    /// `Recherche` is a `Tab(role: .search)`, and on iOS 26 that does not merely select: it
    /// dissolves the tab bar into a search field at the foot of the screen and **withdraws the
    /// navigation bar entirely**, toolbar included. So the search tab is recognised by its field
    /// together with the *absence* of a navigation bar — and the scan action that screen's
    /// toolbar declares is not reachable from there at all, which is why the scenario opens the
    /// scanner from the accueil or from the empty shelf instead.
    enum Tab: String {
        case inventory = "Inventaire"
        case lists = "Listes"
        case search = "Recherche"
        case settings = "Réglages"
    }

    /// Whether one of the app's full-screen flows is over the tabs.
    ///
    /// **A cover does not take the screen behind it out of the accessibility tree.** The
    /// étagères toolbar's « Ranger » button is still there, and still `exists`, while the scanner
    /// is running on top of it — so without this test `isShowingRoot(of: .inventory)` answers
    /// "yes" from inside the scanning session, and the scenario walks on tapping at a tab bar
    /// nobody can reach. Every root test below is written against it.
    private var isCoveredByFlow: Bool {
        exists("e2e.scan.finish")
            || exists("e2e.sort.close")
            || exists("e2e.onboarding.primary")
            || exists("e2e.onboarding.later")
    }

    /// What says "this tab's root is on screen". Also the marker `popBack` walks towards, which
    /// is why each one is something that exists **only** at the root.
    func isShowingRoot(of tab: Tab) -> Bool {
        guard isCoveredByFlow == false else { return false }

        return switch tab {
        case .inventory:
            exists("e2e.shelves.sort")
        case .lists:
            exists("e2e.lists.add")
        case .settings:
            exists("e2e.profile.logout")
        case .search:
            app.navigationBars.count == 0 && app.searchFields.count > 0
        }
    }

    func openTab(_ tab: Tab) throws {
        guard isShowingRoot(of: tab) == false else { return }

        let button: XCUIElement = app.tabBars.buttons[tab.rawValue]

        // A pushed screen can take the tab bar with it, so the way to another tab is sometimes
        // backwards first. Bounded, and silent when it does not help — the tap below is what
        // reports the failure.
        for _ in 0..<4 where button.exists == false {
            let back: XCUIElement = app.navigationBars.buttons["BackButton"]
            guard isReachable(back) else { break }
            back.tap()
            holds({ button.exists }, within: 3)
        }

        try tap(button, "l'onglet « \(tab.rawValue) »", until: { self.isShowingRoot(of: tab) })
    }

    /// Walks back up a tab's stack until its root is on screen again, or gives up. Checked
    /// before every tap, never after, so the root's own trailing action is never mistaken for a
    /// way back.
    func popBack(to tab: Tab, maximum: Int = 6) throws {
        for _ in 0..<maximum {
            if isShowingRoot(of: tab) { return }

            let back: XCUIElement = app.navigationBars.firstMatch.buttons.firstMatch
            guard isReachable(back) else { break }
            if back.isHittable { back.tap() } else { tapAbsolute(back) }
            holds({ self.isShowingRoot(of: tab) }, within: 2)
        }

        guard isShowingRoot(of: tab) else {
            throw E2EFailure("Impossible de revenir à la racine de l'onglet « \(tab.rawValue) ».")
        }
    }
}
