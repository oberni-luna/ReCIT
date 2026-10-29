//
//  CoverFlowGeometry.swift
//  ReCIT_iOS
//
//  How each cover of a list's cover flow is turned, pushed aside, shrunk and shaded, given how
//  far its centre sits from the centre of the strip.
//
//  The strip is a horizontal scroll view whose items all sit one `pitch` apart, so a swipe moves
//  by whole covers and the scroll view's own snapping does the rest. That pitch is far narrower
//  than a cover facing the reader: the covers on either side are drawn turned, and a turned cover
//  is narrow. What makes room for the one in front is `push`, an extra offset that grows with the
//  first pitch of distance and then stays put — so the neighbours slide out of the way as a cover
//  comes to the centre, and the rest of the row keeps its rhythm behind them.
//
//  Everything grows over the first pitch and saturates after it: a cover half-way to the centre
//  is half-turned, which is what makes a swipe read as a continuous movement rather than a cover
//  jumping from one pose to the other. Only the shade keeps deepening with the rank, so the row
//  fades back on both sides.
//
//  Pure by design — no SwiftUI, no scroll view. The view reads `placement(distance:)` inside a
//  `visualEffect`. See PRD 0029 and the `Liste détails` section of the Figma file.
//

import CoreGraphics
import Foundation

struct CoverFlowGeometry: Equatable, Sendable {

    /// What a turned cover's angle, offset, scale and shade are for one distance.
    struct Placement: Equatable, Sendable {
        /// Rotation around the vertical axis, in degrees: positive on the left of the strip,
        /// negative on its right, zero for the cover facing the reader. The sign is SwiftUI's
        /// `rotation3DEffect` one that sends a cover's inner edge — the one nearer the centre —
        /// away from the reader, so a turned cover recedes towards the cover in front.
        let angle: Double
        /// How far the cover is pushed away from the centre, in points, on top of where the
        /// scroll view lays it out.
        let offset: CGFloat
        let scale: CGFloat
        /// How much darker the cover is drawn, from 0 (the cover in front) up.
        let shade: Double
    }

    /// The distance between two neighbours as the scroll view lays them out: the step one swipe
    /// moves by, and the overlap of two turned covers (`38` in the mockup).
    static let pitch: CGFloat = 38

    /// The gap between the cover in front and the turned edge of its neighbour.
    static let gapToFront: CGFloat = 14

    /// The angle of a cover once it has turned away completely.
    static let maxAngle: Double = 55

    /// How much a turned cover shrinks: its outer edge is 234 pt tall against the front cover's
    /// 258 in the mockup.
    static let turnedScale: CGFloat = 0.9

    /// How much darker each rank away from the centre is drawn.
    static let shadePerRank: Double = 0.04

    /// The rank past which the shade stops deepening.
    static let maxShadedRank: Double = 4

    /// The width of the cover facing the reader.
    let coverWidth: CGFloat

    /// How much wider a turned cover looks than nothing: its width, shrunk, seen at its angle.
    var turnedWidth: CGFloat {
        coverWidth * Self.turnedScale * cos(Self.maxAngle * .pi / 180)
    }

    /// The extra offset that clears the front cover: where the first neighbour has to sit — half
    /// the front cover, the gap, half a turned cover — minus where the scroll view puts it.
    var push: CGFloat {
        coverWidth / 2 + Self.gapToFront + turnedWidth / 2 - Self.pitch
    }

    /// The placement of a cover whose centre is `distance` points from the strip's centre,
    /// negative on the left.
    func placement(distance: CGFloat) -> Placement {
        let rank: CGFloat = distance / Self.pitch
        let turn: CGFloat = min(abs(rank), 1)
        let side: CGFloat = rank < 0 ? -1 : 1

        return .init(
            angle: Double(-side * turn) * Self.maxAngle,
            offset: side * turn * push,
            scale: 1 - (1 - Self.turnedScale) * turn,
            shade: Self.shadePerRank * min(Double(abs(rank)), Self.maxShadedRank)
        )
    }
}
