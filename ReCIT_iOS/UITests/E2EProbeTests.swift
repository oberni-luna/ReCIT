//
//  E2EProbeTests.swift
//  ReCIT_iOSUITests
//
//  A scratch pad, not part of the scenario: it signs in and prints the accessibility hierarchy of
//  the screens the scenario has to drive, so a step that cannot find its control can be answered
//  by looking rather than by guessing. Skipped by the `ReCIT_iOSE2E` scheme's test action; run it
//  by name when a step starts failing on an element that is plainly on screen.
//

import XCTest

final class E2EProbeTests: XCTestCase {

    @MainActor
    func testDumpHierarchy() throws {
        continueAfterFailure = true

        let environment: [String: String] = ProcessInfo.processInfo.environment
        let username: String = environment["E2E_USERNAME"] ?? ""
        let password: String = environment["E2E_PASSWORD"] ?? ""

        let app: XCUIApplication = .init()
        app.launchArguments = ["-uitest", "-uitest-reset", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launchEnvironment["E2E_SCAN_CODES"] = "9782370493002,9782413013518"
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["e2e.welcome.signIn"].waitForExistence(timeout: 30))
        app.descendants(matching: .any)["e2e.welcome.signIn"].tap()
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText(username)
        app.secureTextFields.firstMatch.tap()
        app.secureTextFields.firstMatch.typeText(password)
        app.descendants(matching: .any)["e2e.login.submit"].tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 90))

        let later: XCUIElement = app.descendants(matching: .any)["e2e.onboarding.later"]
        if later.waitForExistence(timeout: 60) {
            print("PROBE later hittable=\(later.isHittable) frame=\(later.frame)")
            settle(app, seconds: 2)
            print("PROBE later hittable(after settle)=\(later.isHittable) frame=\(later.frame)")
            for attempt in 0..<6 {
                guard later.exists else { break }
                if later.isHittable { later.tap() } else { tapAbsolute(later, in: app) }
                settle(app, seconds: 2)
                print("PROBE dismiss attempt \(attempt): still up = \(later.exists)")
            }
        }

        print("PROBE ==== tab bar ====")
        print(app.tabBars.firstMatch.debugDescription)

        print("PROBE ==== tab bar buttons ====")
        for index in 0..<app.tabBars.buttons.count {
            let button: XCUIElement = app.tabBars.buttons.element(boundBy: index)
            print("PROBE tab \(index): id=\(button.identifier) label=\(button.label) frame=\(button.frame) hittable=\(button.isHittable)")
        }

        print("PROBE ==== trying to reach the search tab ====")
        let search: XCUIElement = app.tabBars.buttons["Recherche"]
        print("PROBE search exists=\(search.exists) hittable=\(search.isHittable) frame=\(search.frame)")

        print("PROBE nav bar before = \(app.navigationBars.firstMatch.identifier)")
        tapAbsolute(search, in: app)
        settle(app, seconds: 4)
        print("PROBE nav bar after = \(app.navigationBars.firstMatch.identifier)")
        print("PROBE all nav bars = \((0..<app.navigationBars.count).map { app.navigationBars.element(boundBy: $0).identifier })")

        print("PROBE ==== after absolute tap ====")
        print("PROBE searchFields=\(app.searchFields.count) scanExists=\(app.descendants(matching: .any)["e2e.search.scan"].exists)")
        print(app.debugDescription)
    }

    /// Taps the centre of an element's frame in screen coordinates. iOS 26's floating tab bar
    /// reports every one of its buttons as un-hittable, so the ordinary `tap()` path is not
    /// available on them.
    @MainActor
    private func settle(_ app: XCUIApplication, seconds: Double) {
        let deadline: Date = .now.addingTimeInterval(seconds)
        while Date.now < deadline {
            _ = app.wait(for: .runningForeground, timeout: 0.4)
        }
    }

    @MainActor
    private func tapAbsolute(_ element: XCUIElement, in app: XCUIApplication) {
        let frame: CGRect = element.frame
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(.init(dx: frame.midX, dy: frame.midY))
            .tap()
    }
}
