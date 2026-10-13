//
//  MeCentredStack.swift
//  ReCIT_iOS
//
//  Where the empty state of « Tout » puts its parts: « Vous » first, its avatar at the centre of
//  the space — where the graph will put it once someone is there to draw around me — and the
//  rest stacked under it (E1, `602:18269`).
//
//  When the text grows past the room under the centre, « Vous » climbs just enough for the last
//  part to end at the bottom, and no higher than the top: the sentence and the two first steps
//  are what the screen is for, and they are never pushed out of it while there is room.
//
//  Pure geometry on heights, so the rule is testable without a view.
//

import CoreGraphics

nonisolated struct MeCentredStack: Equatable, Sendable {
    /// The height of each part, « Vous » first.
    let heights: [CGFloat]
    /// Between two parts.
    let spacing: CGFloat
    /// The point of « Vous » that goes to the centre, down from its top: its avatar's centre,
    /// not the middle of the avatar and its pill. `nil` for the middle of the part.
    var leadAnchor: CGFloat? = nil

    /// The parts stacked tight, « Vous » first: the least height they fit in.
    var compactHeight: CGFloat {
        guard let lead = heights.first else { return 0 }

        return lead + tailHeight
    }

    /// The top of each part in a space `height` tall, in order.
    func tops(in height: CGFloat) -> [CGFloat] {
        guard let lead = heights.first else { return [] }

        let centred: CGFloat = height / 2 - (leadAnchor ?? lead / 2)
        let bottomAligned: CGFloat = height - compactHeight
        var top: CGFloat = max(min(centred, bottomAligned), 0)
        var tops: [CGFloat] = []
        for partHeight in heights {
            tops.append(top)
            top += partHeight + spacing
        }
        return tops
    }

    /// Everything under « Vous », with the spacing that precedes each part.
    private var tailHeight: CGFloat {
        heights.dropFirst().reduce(0) { $0 + spacing + $1 }
    }
}
