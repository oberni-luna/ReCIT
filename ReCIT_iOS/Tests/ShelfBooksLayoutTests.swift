//
//  ShelfBooksLayoutTests.swift
//  ReCIT_iOSTests
//
//  Unit tests for the pure shelf layout math, including which book a tap lands nearest.
//  Network-free and deterministic (the variance is seeded), so they run in CI. Assert
//  observable output (mode + geometry), not internals. See ADR 0003 / PRD 0001.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite struct ShelfBooksLayoutTests {

    // MARK: - Spine thickness

    @Test func thicknessIsPagesOverFifteenDefaultingTo20() {
        #expect(ShelfBooksLayout.spineWidth(pages: nil) == 20)
        #expect(ShelfBooksLayout.spineWidth(pages: 300) == 20)
    }

    @Test func thicknessIsClamped() {
        #expect(ShelfBooksLayout.spineWidth(pages: 30) == 6)     // 2pt -> floor 6
        #expect(ShelfBooksLayout.spineWidth(pages: 3000) == 70)  // 200pt -> cap 70
    }

    // MARK: - Mode resolution

    @Test func emptyShelfIsVerticalWithNoBooks() {
        let l = ShelfBooksLayout(pageCounts: [], width: 300, zoneHeight: 120)
        #expect(l.mode == .allVertical)
        #expect(l.verticalCount == 0)
        #expect(l.pileRange.isEmpty)
    }

    @Test func singleBookIsFaceOnCover() {
        let l = ShelfBooksLayout(pageCounts: [200], width: 300, zoneHeight: 120)
        #expect(l.mode == .singleCover)
    }

    @Test func everythingFittingStaysAllVertical() {
        // Three ~13pt spines + gaps + lean << 300pt wide.
        let l = ShelfBooksLayout(pageCounts: [200, 200, 200], width: 300, zoneHeight: 120)
        #expect(l.mode == .allVertical)
        #expect(l.verticalCount == 3)
    }

    @Test func overflowSplitsIntoMixed() {
        // 20 thick books (40pt each) can't fit 300pt -> mixed.
        let l = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 20), width: 300, zoneHeight: 120)
        guard case .mixed(let verticalCount) = l.mode else {
            Issue.record("expected mixed, got \(l.mode)")
            return
        }
        #expect(verticalCount >= 1)
        #expect(verticalCount < l.count)
        #expect(l.pileRange == verticalCount..<l.count)
    }

    // MARK: - Height cap

    @Test func spineHeightNeverExceedsZone() {
        let zone: CGFloat = 90
        let l = ShelfBooksLayout(pageCounts: [120, 300, 480, 200, 360], width: 1000, zoneHeight: zone)
        for index in 0..<l.count {
            let height = l.spineSize(at: index).height
            #expect(height <= zone)
            #expect(height >= zone * 0.8)
        }
    }

    // MARK: - Leaning

    @Test func lastStandingBookLeans() {
        let vertical = ShelfBooksLayout(pageCounts: [200, 200, 200], width: 300, zoneHeight: 120)
        #expect(vertical.isLeaning(at: 2))
        #expect(!vertical.isLeaning(at: 0))
        #expect(vertical.leanOffset(at: 2) > 0)
    }

    @Test func mixedHasNoLeaningBook() {
        // A shelf with a pile must not lean any book.
        let l = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 20), width: 300, zoneHeight: 120)
        guard case .mixed = l.mode else {
            Issue.record("expected mixed")
            return
        }
        for index in 0..<l.count {
            #expect(!l.isLeaning(at: index))
        }
    }

    // MARK: - Pile scaling

    @Test func pileScalesToFitTheZone() {
        let zone: CGFloat = 100
        let l = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 20), width: 300, zoneHeight: zone)
        #expect(l.pileScale <= 1)
        let total = l.pileRange.reduce(CGFloat(0)) { $0 + l.pileBarSize(at: $1, availableWidth: 150).height }
        #expect(total <= zone) // scaled pile fits
    }

    @Test func smallPileIsNotUpscaled() {
        // A tiny pile shouldn't be stretched: scale stays 1.
        let l = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 8), width: 200, zoneHeight: 400)
        if case .mixed = l.mode {
            #expect(l.pileScale == 1)
        }
    }

    // MARK: - Nearest book to a tap

    @Test func emptyShelfHasNoNearestBook() {
        let l = ShelfBooksLayout(pageCounts: [], width: 300, zoneHeight: 120)
        #expect(l.nearestIndex(to: .init(x: 150, y: 60)) == nil)
    }

    @Test func loneBookIsAlwaysTheNearest() {
        let l = ShelfBooksLayout(pageCounts: [200], width: 300, zoneHeight: 120)
        #expect(l.nearestIndex(to: .init(x: 0, y: 0)) == 0)
        #expect(l.nearestIndex(to: .init(x: 300, y: 120)) == 0)
    }

    @Test func tapOnAStandingSpineFindsThatSpine() {
        let l = ShelfBooksLayout(pageCounts: [200, 200, 200], width: 300, zoneHeight: 120)
        guard l.mode == .allVertical else {
            Issue.record("expected allVertical")
            return
        }
        for index in 0..<l.count {
            let frame = l.spineFrame(at: index)
            #expect(l.nearestIndex(to: .init(x: frame.midX, y: frame.midY)) == index)
        }
    }

    @Test func standingRunIsCentredInTheZone() {
        let l = ShelfBooksLayout(pageCounts: [200, 200, 200], width: 300, zoneHeight: 120)
        let leftGap = l.spineFrame(at: 0).minX
        let rightGap = 300 - (l.standingRunStartX + l.standingRunWidth)
        #expect(abs(leftGap - rightGap) < 0.001)
    }

    @Test func tapPastTheRunFallsBackToTheClosestSpine() {
        let l = ShelfBooksLayout(pageCounts: [200, 200, 200], width: 300, zoneHeight: 120)
        // Far left of the run, and far right past its end (e.g. a tap on the plank).
        #expect(l.nearestIndex(to: .init(x: -50, y: 200)) == 0)
        #expect(l.nearestIndex(to: .init(x: 400, y: 200)) == l.count - 1)
    }

    @Test func tapOnAPileBarFindsThatBar() {
        let l = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 20), width: 300, zoneHeight: 120)
        guard case .mixed = l.mode else {
            Issue.record("expected mixed")
            return
        }
        for index in l.pileRange {
            let frame = l.pileBarFrame(at: index)
            #expect(l.nearestIndex(to: .init(x: 250, y: frame.midY)) == index)
        }
    }

    @Test func mixedShelfSplitsSpinesLeftAndPileRight() {
        let l = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 20), width: 300, zoneHeight: 120)
        guard case .mixed(let verticalCount) = l.mode else {
            Issue.record("expected mixed")
            return
        }
        // A tap in the left half never picks a pile book, and vice versa.
        let left = l.nearestIndex(to: .init(x: 20, y: 60))
        let right = l.nearestIndex(to: .init(x: 280, y: 60))
        #expect(left.map { $0 < verticalCount } == true)
        #expect(right.map { $0 >= verticalCount } == true)
    }

    @Test func pileIsBottomAlignedAndStacksDownwards() {
        let zone: CGFloat = 120
        let l = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 20), width: 300, zoneHeight: zone)
        guard case .mixed = l.mode else {
            Issue.record("expected mixed")
            return
        }
        let last = l.pileRange.upperBound - 1
        #expect(abs(l.pileBarFrame(at: last).maxY - zone) < 0.001)
        #expect(l.pileBarFrame(at: l.pileRange.lowerBound).minY < l.pileBarFrame(at: last).minY)
    }

    // MARK: - Card metrics

    @Test func everyMetricScalesWithTheCardWidth() {
        let small = ShelfCardMetrics(width: 200)
        let big = ShelfCardMetrics(width: 400)
        #expect(big.zoneHeight == small.zoneHeight * 2)
        #expect(big.plankHeight == small.plankHeight * 2)
        #expect(big.topRoom == small.topRoom * 2)
        #expect(big.cardHeight == small.cardHeight * 2)
    }

    @Test func cardIsItsBooksZonePlusThePlank() {
        let m = ShelfCardMetrics(width: 400)
        #expect(m.cardHeight == m.zoneHeight + m.plankHeight)
        #expect(m.zoneHeight > m.plankHeight) // the books band is the tall part
        #expect(m.booksWidth == m.width - ShelfCardMetrics.horizontalMargin * 2)
    }

    @Test func touchBoxCoversThePlankAndTheRoomAbove() {
        let m = ShelfCardMetrics(width: 400)
        #expect(m.touchBox.contains(CGPoint(x: 200, y: 0)))                 // books
        #expect(m.touchBox.contains(CGPoint(x: 200, y: m.cardHeight - 1)))  // plank
        #expect(m.touchBox.contains(CGPoint(x: 200, y: -m.topRoom + 1)))    // a grown book
        #expect(!m.touchBox.contains(CGPoint(x: 200, y: -m.topRoom - 1)))   // above it
        #expect(!m.touchBox.contains(CGPoint(x: 200, y: m.cardHeight + 1))) // below the card
        #expect(!m.touchBox.contains(CGPoint(x: -1, y: 0)))                 // beside it
    }

    // MARK: - Where a book sits (the focus overlay redraws it there)

    @Test func loneCoverIsCentredAndStandsOnTheShelf() {
        let l = ShelfBooksLayout(pageCounts: [200], width: 300, zoneHeight: 120)
        let cover = l.coverFrame
        #expect(abs(cover.midX - 150) < 0.001)  // centred in the zone
        #expect(abs(cover.maxY - 120) < 0.001)  // sitting on the plank
        #expect(cover.height > 100)             // nearly fills the zone
        #expect(cover.width < cover.height)     // portrait
    }

    @Test func bookFrameFollowsTheShelfsOwnLayout() {
        let lone = ShelfBooksLayout(pageCounts: [200], width: 300, zoneHeight: 120)
        #expect(lone.bookFrame(at: 0) == lone.coverFrame)

        let standing = ShelfBooksLayout(pageCounts: [200, 200, 200], width: 300, zoneHeight: 120)
        #expect(standing.bookFrame(at: 1) == standing.spineFrame(at: 1))

        let mixed = ShelfBooksLayout(pageCounts: Array(repeating: 600, count: 20), width: 300, zoneHeight: 120)
        guard case .mixed(let verticalCount) = mixed.mode else {
            Issue.record("expected mixed")
            return
        }
        #expect(mixed.bookFrame(at: 0) == mixed.spineFrame(at: 0))
        let piled = verticalCount + 1
        #expect(mixed.bookFrame(at: piled) == mixed.pileBarFrame(at: piled))
    }

    @Test func everyBookStandsOnTheSameBaseline() {
        // The focus overlay hangs the cell off this baseline, so it must not move as the
        // finger slides from book to book.
        let l = ShelfBooksLayout(pageCounts: [200, 400, 600], width: 300, zoneHeight: 120)
        let baselines = (0..<l.count).map { l.bookFrame(at: $0).maxY }
        #expect(baselines.allSatisfy { abs($0 - 120) < 0.001 })
    }

    @Test func tallestBookClearsEveryOtherOne() {
        // The focus overlay parks its cell above this, so it must be the maximum, not the
        // first or the last book's height.
        let l = ShelfBooksLayout(pageCounts: [200, 400, 600], width: 300, zoneHeight: 120)
        let heights = (0..<l.count).map { l.bookFrame(at: $0).height }
        #expect(l.tallestBookHeight == heights.max())
        #expect(heights.allSatisfy { $0 <= l.tallestBookHeight })
    }

    @Test func theCellLineClearsEveryGrownBook() {
        let zone: CGFloat = 120
        let l = ShelfBooksLayout(pageCounts: [200, 400, 600], width: 300, zoneHeight: zone)
        let growth: CGFloat = 2
        let line = l.topOfTallestBook(grownBy: growth)
        // Every book, grown about its own centre, stays below the line.
        for index in 0..<l.count {
            let frame = l.bookFrame(at: index)
            let grownTop = frame.midY - frame.height * growth / 2
            #expect(grownTop >= line - 0.001)
        }
        // And the line sits exactly on the tallest one, not above it.
        #expect(abs(line - (zone - l.tallestBookHeight * (1 + growth) / 2)) < 0.001)
    }

    @Test func emptyShelfHasNoTallestBook() {
        let l = ShelfBooksLayout(pageCounts: [], width: 300, zoneHeight: 120)
        #expect(l.tallestBookHeight == 0)
    }
}
