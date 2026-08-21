//
//  DesignSystemFontTests.swift
//  ReCIT_iOSTests
//
//  Every custom font actually resolves.
//
//  This exists because all three OpenSans faces silently did not. `UIFont(name:)` takes a
//  **PostScript** name, which is not always the file name: the faces ship as
//  `OpenSans-Extrabold` and `OpenSans-Semibold` (lowercase `b`), and the regular one is
//  plain `OpenSans`. Every mismatch returns nil, `TextStyle.uiFont` falls back to
//  `.systemFont`, and the app renders San Francisco where the design says Open Sans —
//  with nothing in the console to say so. `Bundle.url(forResource:)` is case-sensitive
//  too, so one of the files was never even registered.
//
//  A test is the only thing that catches this class of bug: it is invisible to the
//  compiler, and on screen it looks like a design decision.
//

import Testing
import UIKit
@testable import ReCIT_iOS

@Suite("Design system fonts")
@MainActor
struct DesignSystemFontTests {

    init() {
        // Registration is idempotent, and the suite must not depend on the app having
        // booted first.
        DesignSystem.start()
    }

    /// Every declared face ships in the bundle under the name the registration looks for.
    @Test("Every custom font file is in the bundle under the name we register it by", arguments: DesignSystem.TextStyle.CustomFont.allCases)
    func theFontFileIsInTheBundle(_ font: DesignSystem.TextStyle.CustomFont) {
        let url: URL? = Bundle.main.url(forResource: font.registrationName, withExtension: font.fileExtension)

        #expect(url != nil, "No \(font.registrationName).\(font.fileExtension) in the bundle")
    }

    /// And resolves to a real font, rather than falling back to the system one.
    @Test("Every custom font resolves by its PostScript name", arguments: DesignSystem.TextStyle.CustomFont.allCases)
    func theFontResolvesByName(_ font: DesignSystem.TextStyle.CustomFont) {
        let resolved: UIFont? = UIFont(name: font.fontName, size: 17)

        #expect(resolved != nil, "\(font.fontName) does not resolve — the style will fall back to the system font")
        #expect(resolved?.fontName == font.fontName)
    }

    /// The check that matters to the user: no text style is quietly drawn in San
    /// Francisco. A style whose `customFont` is declared must end up using it.
    @Test("No text style falls back to the system font", arguments: DesignSystem.TextStyle.allCases)
    func theStyleUsesItsDeclaredFont(_ style: DesignSystem.TextStyle) {
        guard let expected = style.customFont else { return }

        #expect(
            style.uiFont.fontName == expected.fontName,
            "\(style) draws in \(style.uiFont.fontName) instead of \(expected.fontName)"
        )
    }
}
