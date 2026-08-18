//
//  ShelfBooksLayout.swift
//  ReCIT_iOS
//
//  Pure (SwiftUI-free) layout math for the books on a shelf. Given the ordered books'
//  page counts and the shelf's usable width + zone height, it resolves the layout mode,
//  all per-book geometry, and which book a tap lands nearest. `ShelfBooksView` is a thin
//  renderer over this. Kept free of SwiftData/SwiftUI so it can be unit-tested in
//  isolation. See ADR 0003.
//

import CoreGraphics
import Foundation

struct ShelfBooksLayout: Equatable {

    enum Mode: Equatable {
        /// A lone book, shown face-on with its cover.
        case singleCover
        /// Every book stands as a spine (the last one leaning). Also the empty case.
        case allVertical
        /// Left `verticalCount` books stand; the rest form a horizontal pile.
        case mixed(verticalCount: Int)
    }

    let count: Int
    let width: CGFloat
    let zoneHeight: CGFloat
    let mode: Mode

    private let pages: [Int?]

    static let spacing: CGFloat = 2
    static let leanDegrees: Double = 10

    init(pageCounts: [Int?], width: CGFloat, zoneHeight: CGFloat) {
        self.pages = pageCounts
        self.count = pageCounts.count
        self.width = width
        self.zoneHeight = zoneHeight
        self.mode = Self.resolveMode(pages: pageCounts, width: width, zoneHeight: zoneHeight)
    }

    // MARK: - Derived ranges

    /// Number of standing spines: all of them when `allVertical`, the split when `mixed`.
    var verticalCount: Int {
        switch mode {
        case .allVertical: return count
        case .mixed(let verticalCount): return verticalCount
        case .singleCover: return 0
        }
    }

    /// Books that form the horizontal pile (empty unless `mixed`).
    var pileRange: Range<Int> {
        if case .mixed(let verticalCount) = mode { return verticalCount..<count }
        return count..<count
    }

    // MARK: - Vertical spine geometry

    func spineSize(at index: Int) -> CGSize {
        .init(width: Self.spineWidth(pages: pages[index]), height: Self.spineHeight(index: index, zoneHeight: zoneHeight))
    }

    /// Whether the book at `index` is the leaning one — only in the all-vertical case
    /// (a shelf with a horizontal pile never has a leaning book).
    func isLeaning(at index: Int) -> Bool {
        switch mode {
        case .allVertical: return count > 1 && index == count - 1
        case .mixed, .singleCover: return false
        }
    }

    /// Rightward nudge so the leaning book rests on the previous one's top corner.
    func leanOffset(at index: Int) -> CGFloat {
        let previousHeight: CGFloat = index > 0
            ? Self.spineHeight(index: index - 1, zoneHeight: zoneHeight)
            : Self.spineHeight(index: index, zoneHeight: zoneHeight)
        return previousHeight * tan(Self.leanRadians)
    }

    // MARK: - Pile geometry

    /// Scales the pile's summed thicknesses to fit the books zone.
    var pileScale: CGFloat {
        let total: CGFloat = pileRange.reduce(0) { $0 + Self.rawThickness(pages: pages[$1]) }
        let available: CGFloat = zoneHeight * 0.96
        return total > available ? available / total : 1
    }

    func pileBarSize(at index: Int, availableWidth: CGFloat) -> CGSize {
        .init(
            width: availableWidth * Self.vary(index + 2, 0.72, 0.98),
            height: Self.rawThickness(pages: pages[index]) * pileScale
        )
    }

    func pileJitter(at index: Int) -> CGFloat {
        let pattern: [CGFloat] = [-3, 2, -1, 3, -2, 1, -3, 2, 0, -1]
        return pattern[index % pattern.count]
    }

    // MARK: - Frames in the books zone

    /// Overlap between two stacked pile bars (the pile's negative spacing).
    static let pileOverlap: CGFloat = 1

    /// Width the standing run occupies: spines plus the gaps between them.
    var standingRunWidth: CGFloat {
        let count: Int = verticalCount
        guard count > 0 else { return 0 }
        let spines: CGFloat = (0..<count).reduce(0) { $0 + Self.spineWidth(pages: pages[$1]) }
        return spines + Self.spacing * CGFloat(count - 1)
    }

    /// Where the standing run starts: centred when every book stands, hard left when a
    /// pile shares the zone (the run then owns the left half).
    var standingRunStartX: CGFloat {
        switch mode {
        case .allVertical: return max((width - standingRunWidth) / 2, 0)
        case .mixed, .singleCover: return 0
        }
    }

    /// Width available to the pile — the right half of the zone.
    var pileColumnWidth: CGFloat { width / 2 }

    /// Frame of the standing spine at `index`, in the books zone's coordinates (origin
    /// top-left, books sitting on the bottom edge).
    func spineFrame(at index: Int) -> CGRect {
        let leading: CGFloat = (0..<index).reduce(standingRunStartX) {
            $0 + Self.spineWidth(pages: pages[$1]) + Self.spacing
        }
        let size: CGSize = spineSize(at: index)
        let lean: CGFloat = isLeaning(at: index) ? leanOffset(at: index) : 0
        return .init(
            x: leading + lean,
            y: zoneHeight - size.height,
            width: size.width,
            height: size.height
        )
    }

    /// Frame of the pile bar at `index`, in the books zone's coordinates. The pile is
    /// bottom-aligned in the right half, each bar overlapping the one below by 1pt.
    func pileBarFrame(at index: Int) -> CGRect {
        let heights: [CGFloat] = pileRange.map {
            pileBarSize(at: $0, availableWidth: pileColumnWidth).height
        }
        let stacked: CGFloat = heights.reduce(0, +)
            - Self.pileOverlap * CGFloat(max(heights.count - 1, 0))
        let first: Int = pileRange.lowerBound
        let above: CGFloat = (first..<index).reduce(0) {
            $0 + heights[$1 - first] - Self.pileOverlap
        }
        let size: CGSize = pileBarSize(at: index, availableWidth: pileColumnWidth)
        // The pile hugs the zone's right edge, and the bars are centred on each other.
        let widest: CGFloat = pileRange.reduce(0) {
            max($0, pileBarSize(at: $1, availableWidth: pileColumnWidth).width)
        }
        return .init(
            x: width - widest + (widest - size.width) / 2,
            y: zoneHeight - stacked + above,
            width: size.width,
            height: size.height
        )
    }

    // MARK: - Hit testing

    /// The book nearest `point` (books-zone coordinates). Never `nil` on a non-empty
    /// shelf: a tap past the run, above the books or on the plank resolves to the
    /// closest book rather than to nothing.
    func nearestIndex(to point: CGPoint) -> Int? {
        guard count > 0 else { return nil }
        switch mode {
        case .singleCover:
            return 0
        case .allVertical:
            return nearestStandingIndex(x: point.x)
        case .mixed:
            // The zone splits down the middle: spines left, pile right. Within the pile
            // the bars stack, so there it is the vertical position that picks the book.
            return point.x < width / 2
                ? nearestStandingIndex(x: point.x)
                : nearestPileIndex(y: point.y)
        }
    }

    private func nearestStandingIndex(x: CGFloat) -> Int? {
        (0..<verticalCount).min {
            let first: CGRect = spineFrame(at: $0)
            let second: CGRect = spineFrame(at: $1)
            return Self.gap(x, first.minX, first.maxX) < Self.gap(x, second.minX, second.maxX)
        }
    }

    private func nearestPileIndex(y: CGFloat) -> Int? {
        pileRange.min {
            let first: CGRect = pileBarFrame(at: $0)
            let second: CGRect = pileBarFrame(at: $1)
            return Self.gap(y, first.minY, first.maxY) < Self.gap(y, second.minY, second.maxY)
        }
    }

    /// Distance from `value` to the closed range `low...high` (0 when inside).
    private static func gap(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        if value < low { return low - value }
        if value > high { return value - high }
        return 0
    }

    // MARK: - Shared

    /// Deterministic per-book seed for the watercolour shader / variance.
    static func seed(_ index: Int) -> Double { Double(index) * 1.73 + 0.4 }

    // MARK: - Pure core

    private static var leanRadians: CGFloat { CGFloat(leanDegrees) * .pi / 180 }

    /// Spine thickness from page count: 1pt / 15 pages, default 20pt, clamped 6–70.
    static func spineWidth(pages: Int?) -> CGFloat {
        let raw: CGFloat = pages.map { CGFloat($0) / 15.0 } ?? 20
        return min(max(raw, 6), 70)
    }

    static func spineHeight(index: Int, zoneHeight: CGFloat) -> CGFloat {
        zoneHeight * vary(index, 0.80, 1.0)
    }

    /// Lying-book thickness (same page basis as a spine, capped lower so piles fit).
    static func rawThickness(pages: Int?) -> CGFloat {
        let raw: CGFloat = pages.map { CGFloat($0) / 15.0 } ?? 20
        return min(max(raw, 6), 40)
    }

    /// Deterministic pseudo-variance so sizes differ without randomness.
    static func vary(_ index: Int, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        let seq: [CGFloat] = [0.15, 0.72, 0.38, 0.9, 0.05, 0.55, 0.27, 0.83, 0.46, 0.66]
        return low + (high - low) * seq[index % seq.count]
    }

    // MARK: - Mode resolution

    private static func resolveMode(pages: [Int?], width: CGFloat, zoneHeight: CGFloat) -> Mode {
        let count: Int = pages.count
        if count == 1 { return .singleCover }
        if count == 0 { return .allVertical }
        if totalVerticalWidth(pages: pages, zoneHeight: zoneHeight) <= width {
            return .allVertical
        }
        return .mixed(verticalCount: verticalCountForHalf(pages: pages, width: width))
    }

    /// Width the whole run needs standing vertically: spines + gaps + the horizontal
    /// room the leaning last book takes.
    static func totalVerticalWidth(pages: [Int?], zoneHeight: CGFloat) -> CGFloat {
        let count: Int = pages.count
        let sum: CGFloat = pages.reduce(0) { $0 + spineWidth(pages: $1) }
        let gaps: CGFloat = spacing * CGFloat(max(count - 1, 0))
        let leanExtra: CGFloat = count > 1
            ? spineHeight(index: count - 1, zoneHeight: zoneHeight) * sin(leanRadians)
            : 0
        return sum + gaps + leanExtra
    }

    /// How many books fill (roughly) the left half before switching to the pile.
    static func verticalCountForHalf(pages: [Int?], width: CGFloat) -> Int {
        let half: CGFloat = width / 2
        var accumulated: CGFloat = 0
        var count: Int = 0
        for page in pages {
            let next: CGFloat = accumulated + spineWidth(pages: page) + (count > 0 ? spacing : 0)
            if next > half && count >= 1 { break }
            accumulated = next
            count += 1
        }
        return max(min(count, pages.count - 1), 1)
    }
}
