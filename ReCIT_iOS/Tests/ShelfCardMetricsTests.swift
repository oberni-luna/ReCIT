//
//  ShelfCardMetricsTests.swift
//  ReCIT_iOSTests
//
//  The carousel's card width: a phone keeps its 86 %, a wider screen stops at the widest
//  phone's card and shows more étagères instead.
//

import Testing
import CoreGraphics
@testable import ReCIT_iOS

@Suite("ShelfCardMetrics")
struct ShelfCardMetricsTests {

    /// iPhone SE, iPhone 13 mini / SE 3, iPhone 17, iPhone 17 Pro Max.
    @Test(arguments: [320, 375, 393, 430] as [CGFloat])
    func aPhoneKeepsItsShare(width: CGFloat) {
        let card: CGFloat = ShelfCardMetrics.carouselCardWidth(containerWidth: width)

        #expect(abs(card - width * ShelfCardMetrics.carouselShare) < 0.01)
    }

    /// The iPhone Duo: folded, unfolded in portrait, unfolded in landscape.
    @Test(arguments: [466, 669, 951] as [CGFloat])
    func aWiderScreenStopsAtTheWidestPhonesCard(width: CGFloat) {
        let card: CGFloat = ShelfCardMetrics.carouselCardWidth(containerWidth: width)

        #expect(card == ShelfCardMetrics.maxCarouselCardWidth)
        #expect(card < width * ShelfCardMetrics.carouselShare)
    }
}
