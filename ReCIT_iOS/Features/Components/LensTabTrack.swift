//
//  LensTabTrack.swift
//  ReCIT_iOS
//
//  The geometry of `LensTabPicker`, kept apart from the view so it can be tested: where the
//  capsule is drawn for a position between the words, which position puts its centre under a
//  finger, how far it is let past the first and last word, and which word it settles on when let
//  go.
//
//  A position is a word's index, in between while the capsule is between two: 0 on the first,
//  1.5 halfway from the second to the third. The capsule's frame goes in a straight line from one
//  word's frame to the next as the position goes from one index to the next, so its centre does
//  too, which is what lets a finger's x be read back into a position.
//

import CoreGraphics

struct LensTabTrack {
    /// The most the capsule can be pulled past the first or last word, approached but never
    /// reached, as a scroll view's rubber band.
    static let overshootLimit: CGFloat = 36
    /// How much of the overshoot stretches the capsule rather than moves it.
    static let overshootStretch: CGFloat = 0.5
    /// How far ahead of the finger a release looks, at the finger's speed — a tenth of a second.
    static let flingProjection: CGFloat = 0.1

    /// Each word's frame, in the picker's order.
    let frames: [CGRect]

    var lastIndex: CGFloat {
        CGFloat(max(frames.count - 1, 0))
    }

    func clamped(_ position: CGFloat) -> CGFloat {
        min(max(position, 0), lastIndex)
    }

    /// Between the frames of the two words the position stands between, by how far it has gone.
    func capsuleFrame(at position: CGFloat) -> CGRect? {
        guard frames.isEmpty == false else { return nil }

        let position: CGFloat = clamped(position)
        let lower: Int = Int(position.rounded(.down))
        let upper: Int = min(lower + 1, frames.count - 1)
        let from: CGRect = frames[lower]
        let to: CGRect = frames[upper]
        let progress: CGFloat = position - CGFloat(lower)
        return .init(
            x: from.minX + (to.minX - from.minX) * progress,
            y: from.minY,
            width: from.width + (to.width - from.width) * progress,
            height: from.height
        )
    }

    /// The capsule's frame grown about its centre by `scale` while lifted, and pulled past the end
    /// by `overshoot` — partly moved, partly stretched towards the finger, the far edge following
    /// it whole and the near one by half, a little flattened as it stretches.
    func lensFrame(
        at position: CGFloat,
        scale: CGFloat,
        overshoot: CGFloat
    ) -> CGRect? {
        guard let frame = capsuleFrame(at: position) else { return nil }

        let stretch: CGFloat = abs(overshoot) * Self.overshootStretch
        let towardsFinger: CGFloat = overshoot < 0 ? -stretch : stretch
        return frame
            .insetBy(
                dx: -frame.width * (scale - 1) / 2 - stretch / 2,
                dy: -frame.height * (scale - 1) / 2 + stretch / 8
            )
            .offsetBy(dx: overshoot - towardsFinger / 2, dy: 0)
    }

    /// The position at which the capsule's centre is at `x`, the first or last word's past them.
    /// `nil` until the words have been measured.
    func position(forCenter x: CGFloat) -> CGFloat? {
        let centers: [CGFloat] = frames.map(\.midX)
        guard let first = centers.first, let last = centers.last else { return nil }
        if x <= first { return 0 }
        if x >= last { return lastIndex }

        for index in 0..<(centers.count - 1) where x < centers[index + 1] {
            return CGFloat(index) + (x - centers[index]) / (centers[index + 1] - centers[index])
        }
        return lastIndex
    }

    /// How far past the first or last word's centre the capsule's centre is pulled at `x`,
    /// damped: negative before the first, positive after the last, 0 in between.
    func overshoot(forCenter x: CGFloat) -> CGFloat {
        guard let first = frames.first?.midX, let last = frames.last?.midX else { return 0 }
        if x < first { return -Self.rubberBand(first - x) }
        if x > last { return Self.rubberBand(x - last) }
        return 0
    }

    /// A scroll view's rubber band: as much as pulled at first, less and less after, never past
    /// `overshootLimit`.
    static func rubberBand(_ distance: CGFloat) -> CGFloat {
        overshootLimit * (1 - 1 / (distance * 0.55 / overshootLimit + 1))
    }

    /// The word the capsule settles on when let go with its centre at `center`, the finger going
    /// at `velocity` points a second: the nearest to where it would be a tenth of a second later,
    /// and never more than one word from the nearest to where it is.
    func releaseIndex(position: CGFloat, center: CGFloat, velocity: CGFloat) -> Int {
        let current: CGFloat = clamped(position).rounded()
        let limit: CGFloat = Self.overshootLimit * 2
        let projection: CGFloat = min(max(velocity * Self.flingProjection, -limit), limit)
        let thrown: CGFloat = self.position(forCenter: center + projection) ?? current
        return Int(clamped(min(max(thrown.rounded(), current - 1), current + 1)))
    }

    /// The word a tap at `location` lands on, `nil` outside all of them.
    func index(at location: CGFloat) -> Int? {
        frames.firstIndex { $0.minX...$0.maxX ~= location }
    }
}
