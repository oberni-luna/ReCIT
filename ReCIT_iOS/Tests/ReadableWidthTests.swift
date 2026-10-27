//
//  ReadableWidthTests.swift
//  ReCIT_iOSTests
//
//  The readable column: nothing changes on a phone or on the folded iPhone Duo; unfolded, a
//  list's content narrows to 540 pt, centred.
//

import Testing
import CoreGraphics
@testable import ReCIT_iOS

@Suite("ReadableWidth")
struct ReadableWidthTests {

    /// Every phone, and the folded iPhone Duo.
    @Test(arguments: [0, 320, 375, 393, 430, 466] as [CGFloat])
    func aPhoneKeepsTheListsOwnMargins(width: CGFloat) {
        #expect(DesignSystem.ReadableWidth.scrollContentMargin(containerWidth: width) == nil)
    }

    /// The unfolded iPhone Duo, in portrait and in landscape.
    @Test(arguments: [669, 951] as [CGFloat])
    func aWideScreenNarrowsTheColumnToItsMaximum(width: CGFloat) throws {
        let margin: CGFloat = try #require(DesignSystem.ReadableWidth.scrollContentMargin(containerWidth: width))

        #expect(abs(width - margin * 2 - DesignSystem.ReadableWidth.maximum) < 0.01)
    }
}
