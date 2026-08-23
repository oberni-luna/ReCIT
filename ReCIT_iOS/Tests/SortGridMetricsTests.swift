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

    /// A small collection gets two columns. Three narrow cards with two empty slots beside them
    /// read as a screen that failed to load rather than as a library of two.
    @Test(arguments: [0, 1, 2]) func aSmallCollectionUsesTwoColumns(shelfCount: Int) {
        #expect(SortGridMetrics.columnCount(forShelfCount: shelfCount) == 2)
    }

    @Test(arguments: [3, 4, 12, 40]) func aFullCollectionUsesThreeColumns(shelfCount: Int) {
        #expect(SortGridMetrics.columnCount(forShelfCount: shelfCount) == 3)
    }

    /// Whatever the column count, the row fills its width exactly: the owner's formula
    /// generalised, so two columns are two wide cards rather than three cards with a hole.
    @Test(arguments: [2, 3]) func everyColumnCountFillsTheWidth(columns: Int) {
        for width in widths {
            let metrics: SortGridMetrics = .init(containerWidth: width)
            let card: CGFloat = metrics.shelfColumnWidth(columns: columns)
            let laidOut: CGFloat = card * CGFloat(columns)
                + SortGridMetrics.shelfSpacing * CGFloat(columns + 1)

            #expect(abs(laidOut - width) < 0.01)
        }
    }

    @Test func twoColumnsAreWiderThanThree() {
        let metrics: SortGridMetrics = .init(containerWidth: 393)

        #expect(metrics.shelfColumnWidth(columns: 2) > metrics.shelfColumnWidth(columns: 3))
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
