//
//  SortGridMetricsTests.swift
//  ReCIT_iOSTests
//
//  The sorting surface's measurements, at the four widths the app actually runs at. Three
//  columns must stay three columns: a card sized for a 393 pt screen wraps on a 375 pt one,
//  and nobody notices until an SE turns up. See PRD 0009.
//

import Testing
import CoreGraphics
@testable import ReCIT_iOS

@Suite("SortGridMetrics")
struct SortGridMetricsTests {

    /// iPhone SE, iPhone 13 mini / SE 3, iPhone 17, iPhone 17 Pro Max.
    private let widths: [CGFloat] = [320, 375, 393, 430]

    // MARK: - Étagères

    /// The owner's formula: `3W + 4 × 16 = width`.
    @Test func theShelfGridFillsItsWidthExactly() {
        for width in widths {
            let metrics: SortGridMetrics = .init(containerWidth: width)
            let laidOut: CGFloat = metrics.shelfColumnWidth * 3 + SortGridMetrics.shelfSpacing * 4

            #expect(abs(laidOut - width) < 0.01)
        }
    }

    @Test func theShelfColumnMatchesTheMockupOnAThreeNinetyThreeScreen() {
        let metrics: SortGridMetrics = .init(containerWidth: 393)

        #expect(abs(metrics.shelfColumnWidth - 109.666) < 0.01)
    }

    // MARK: - Livres à ranger

    /// Three cards, three gutters, one margin, and 40 pt of the fourth card showing — the
    /// peek is the only thing that says the carousel scrolls.
    @Test func theCarouselLeavesRoomForAPeek() {
        for width in widths {
            let metrics: SortGridMetrics = .init(containerWidth: width)
            let laidOut: CGFloat = SortGridMetrics.shelfSpacing
                + metrics.bookColumnWidth * 3
                + SortGridMetrics.bookSpacing * 3

            #expect(width - laidOut > SortGridMetrics.bookPeek - 0.01)
        }
    }

    @Test func theBookColumnMatchesTheMockupOnAThreeNinetyThreeScreen() {
        let metrics: SortGridMetrics = .init(containerWidth: 393)

        #expect(abs(metrics.bookColumnWidth - 100.333) < 0.01)
    }

    // MARK: - Both

    @Test func aBookCardIsNarrowerThanAnEtagereCard() {
        for width in widths {
            let metrics: SortGridMetrics = .init(containerWidth: width)

            #expect(metrics.bookColumnWidth < metrics.shelfColumnWidth)
        }
    }

    @Test func everyColumnStaysPositiveAtEveryWidth() {
        for width in widths {
            let metrics: SortGridMetrics = .init(containerWidth: width)

            #expect(metrics.shelfColumnWidth > 0)
            #expect(metrics.bookColumnWidth > 0)
        }
    }

    /// A width smaller than the margins it has to honour yields zero rather than a negative
    /// frame, which SwiftUI would render as a runtime complaint on a screen nobody can see.
    @Test func anAbsurdWidthYieldsNoNegativeColumn() {
        let metrics: SortGridMetrics = .init(containerWidth: 8)

        #expect(metrics.shelfColumnWidth == 0)
        #expect(metrics.bookColumnWidth == 0)
    }

    // MARK: - Covers

    @Test func aCoverReservesATwoToThreeFrame() {
        let size: CGSize = SortGridMetrics.coverSize(width: 60)

        #expect(abs(size.height - 90) < 0.01)
    }
}
