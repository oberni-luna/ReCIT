//
//  CoverWallGeometry.swift
//  ReCIT_iOS
//
//  Where every cover of the wall sits, and where it sits a second and a half later.
//
//  The wall is a grid of columns that slide past each other — odd columns down, even columns
//  up — behind the welcome screen. Two properties have to hold at every instant, and neither
//  is visible in a screenshot: the grid **tiles** the container (no gap ever opens at the top
//  of a column as it drifts), and the drift **loops** (at the end of a period a column is back
//  where it started, without a jump). Both are arithmetic, so both are asserted rather than
//  eyeballed — see `CoverWallGeometryTests`.
//
//  The trick that buys the loop is a single `truncatingRemainder`: a column draws
//  `rowCount` covers, one row pitch apart, and each row's `y` is wrapped into
//  `[-rowPitch, period - rowPitch)`. A cover that walks off one end reappears at the other,
//  so `rowCount` covers are enough for an infinite scroll, and the period is exactly the
//  height of the stack. `rowCount` overdraws by two rows precisely so the wrapped band is
//  taller than the container.
//
//  Time enters as an elapsed number of seconds, not as an animation: the renderer reads a
//  clock (`TimelineView`) and asks where things are *now*. Nothing here is stateful, so a
//  return from standby, a rotation or a text-size change cannot leave the wall half-animated —
//  there is no animation to interrupt.
//
//  Pure by design — no SwiftUI, no device, no images. See PRD 0011.
//

import CoreGraphics
import Foundation

struct CoverWallGeometry: Equatable, Sendable {

    /// How many columns the wall is drawn on. Four on a phone, from the mockup
    /// (`Nouveau récits`, `265:7532`).
    static let defaultColumnCount: Int = 4

    /// The gap between two covers, horizontally and vertically, and the wall's own margin.
    static let gutter: CGFloat = 8

    /// A cover's shape: width ÷ height. Every cover is drawn in this frame whatever its real
    /// proportions, because the wall must tile before any image has arrived — and the images
    /// arrive at sixty different ratios.
    static let coverAspectRatio: CGFloat = 2.0 / 3.0

    /// Each column's speed, in points per second. Deliberately close together and
    /// deliberately not equal: equal speeds make the wall read as one sheet sliding, which is
    /// what a wallpaper does. Slow enough to be read past — a cover takes about ten seconds
    /// to cross its own height.
    static let columnSpeeds: [CGFloat] = [12, 15, 10.5, 13.5]

    /// Each column's head start, as a fraction of one row pitch. Without it the columns start
    /// aligned and the wall opens on a perfect checkerboard, which no bookshelf has ever been.
    /// Distinct values, and none a multiple of another.
    static let columnPhases: [CGFloat] = [0, 0.41, 0.17, 0.68]

    /// Rows drawn beyond the ones the container needs. Two, because the wrapped band spans
    /// `[-rowPitch, period - rowPitch)`: one row pays for the negative end, one for the
    /// remainder at the bottom.
    static let overdraw: Int = 2

    /// The space the wall was given.
    let size: CGSize
    let columnCount: Int
    let coverWidth: CGFloat
    let coverHeight: CGFloat
    /// How many covers each column draws. Enough to tile the container at any offset.
    let rowCount: Int

    init(size: CGSize, columnCount: Int = Self.defaultColumnCount) {
        let columns: Int = max(1, columnCount)
        let available: CGFloat = max(0, size.width) - CGFloat(columns + 1) * Self.gutter
        let width: CGFloat = max(0, available / CGFloat(columns))

        self.size = size
        self.columnCount = columns
        self.coverWidth = width
        self.coverHeight = width / Self.coverAspectRatio

        // A container with no width has no covers to draw, and a cover of zero height would
        // make the period one gutter tall — a wall of nothing, looping furiously.
        let pitch: CGFloat = width / Self.coverAspectRatio + Self.gutter
        let hasRoom: Bool = width > 0 && size.height > 0
        self.rowCount = hasRoom ? Int(ceil(size.height / pitch)) + Self.overdraw : 0
    }

    // MARK: - Derived measurements

    /// One row's stride: a cover plus the gap under it.
    var rowPitch: CGFloat {
        coverHeight + Self.gutter
    }

    /// How far a column travels before it is back where it started. The loop is exactly this
    /// long, which is what makes it seamless: the stack is `period` tall and wraps onto itself.
    var period: CGFloat {
        CGFloat(rowCount) * rowPitch
    }

    /// The left edge of a column.
    func x(ofColumn column: Int) -> CGFloat {
        Self.gutter + CGFloat(column) * (coverWidth + Self.gutter)
    }

    /// `1` when the column travels downward, `-1` upward. The first column goes down, and they
    /// alternate from there.
    func direction(ofColumn column: Int) -> CGFloat {
        column.isMultiple(of: 2) ? 1 : -1
    }

    /// This column's speed, in points per second.
    func speed(ofColumn column: Int) -> CGFloat {
        Self.columnSpeeds[column % Self.columnSpeeds.count]
    }

    /// This column's head start, in points.
    func phase(ofColumn column: Int) -> CGFloat {
        Self.columnPhases[column % Self.columnPhases.count] * rowPitch
    }

    /// The top edge of one cover, `elapsed` seconds in.
    ///
    /// `speedScale` scales every column at once: `0` freezes the wall where its phases put it,
    /// which is what "Reduce Motion" and the low-power mode ask for, and `1` is the
    /// mockup's pace.
    func y(
        ofRow row: Int,
        inColumn column: Int,
        at elapsed: TimeInterval,
        speedScale: CGFloat = 1
    ) -> CGFloat {
        guard rowCount > 0 else { return 0 }

        let travelled: CGFloat = direction(ofColumn: column)
            * speed(ofColumn: column)
            * speedScale
            * CGFloat(elapsed)
        let raw: CGFloat = CGFloat(row) * rowPitch + travelled + phase(ofColumn: column)

        return wrapped(raw)
    }

    /// Folds a position into the band the wall draws in — one row above the container, and the
    /// rest of the period below. This single line is the whole seamless loop.
    private func wrapped(_ y: CGFloat) -> CGFloat {
        let shifted: CGFloat = y + rowPitch
        let remainder: CGFloat = shifted.truncatingRemainder(dividingBy: period)
        let positive: CGFloat = remainder < 0 ? remainder + period : remainder

        return positive - rowPitch
    }

    // MARK: - What goes in a slot

    /// Which cover of `imageCount` belongs in this slot, or `nil` when there is no image to
    /// put anywhere — the caller paints one instead, and a slot is never left empty.
    ///
    /// A raster fill, on purpose: with sixty covers and a grid of about thirty-two slots no
    /// image is drawn twice, so nothing repeats side by side. When there are fewer images than
    /// slots the fill cycles, which repeats — but a wall of four covers should look like four
    /// covers rather than like four covers and some holes.
    func imageIndex(ofRow row: Int, inColumn column: Int, imageCount: Int) -> Int? {
        guard imageCount > 0 else { return nil }

        return slot(row: row, column: column) % imageCount
    }

    /// Which painted variant belongs in this slot. Same raster fill, so the painted wall is
    /// deterministic: the same size gives the same wall, which is what makes it reviewable.
    func paintedIndex(ofRow row: Int, inColumn column: Int, variantCount: Int) -> Int {
        guard variantCount > 0 else { return 0 }

        return slot(row: row, column: column) % variantCount
    }

    private func slot(row: Int, column: Int) -> Int {
        max(0, row) * columnCount + max(0, column)
    }
}
