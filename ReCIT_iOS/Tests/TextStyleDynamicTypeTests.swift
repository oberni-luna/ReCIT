//
//  TextStyleDynamicTypeTests.swift
//  ReCIT_iOSTests
//
//  A design-system style follows the text size of the view it is drawn in — the environment's,
//  cap included — not only the app's. The Réseau graph caps its text at `.xxxLarge` (PRD 0019,
//  Q43), and a cap the fonts ignored was no cap: `uiFont` is scaled once, to the app's size,
//  where `.dynamicTypeSize(...)` never reaches.
//

import SwiftUI
import Testing
import UIKit
@testable import ReCIT_iOS

@Suite("TextStyle and Dynamic Type")
@MainActor
struct TextStyleDynamicTypeTests {

    init() {
        DesignSystem.start()
    }

    @Test("At the default size, a style is drawn at its own size", arguments: DesignSystem.TextStyle.allCases)
    func defaultSize(_ style: DesignSystem.TextStyle) {
        #expect(abs(style.uiFont(for: .large).pointSize - style.size) < 0.01)
    }

    @Test("A style grows with the text size it is asked for", arguments: DesignSystem.TextStyle.allCases)
    func grows(_ style: DesignSystem.TextStyle) {
        let small: CGFloat = style.uiFont(for: .xSmall).pointSize
        let large: CGFloat = style.uiFont(for: .large).pointSize
        let capped: CGFloat = style.uiFont(for: .xxxLarge).pointSize
        let accessibility: CGFloat = style.uiFont(for: .accessibility5).pointSize

        #expect(small <= large)
        #expect(large < capped)
        #expect(capped < accessibility)
    }

    @Test("The face does not change with the size", arguments: DesignSystem.TextStyle.allCases)
    func sameFace(_ style: DesignSystem.TextStyle) {
        #expect(style.uiFont(for: .accessibility3).fontName == style.uiFont(for: .large).fontName)
    }
}
