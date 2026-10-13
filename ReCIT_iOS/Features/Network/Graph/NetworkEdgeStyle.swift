//
//  NetworkEdgeStyle.swift
//  ReCIT_iOS
//
//  How a line of the Réseau graph is stroked, by its kind and the level drawn (PRD 0019, Q32,
//  Q32 bis): two sets — the full graph is R1, the overview is R3 — and one dash for everything
//  that waits on my answer.
//
//  Full (R1): to a group, from me or from a friend, 1.5 pt at 60 %; from me to a friend, 1 pt at
//  30 %; dashed, 1.5 pt at full strength.
//  Overview (R3): from me to a group, solid or dashed, 2 pt at 80 %; from a friend to a group,
//  1 pt at 30 %; from me to a friend still 1 pt at 30 % (Q32 bis); a requester's dashed line as
//  in full.
//
//  A value, so the canvas strokes one path per style.
//

import CoreGraphics

struct NetworkEdgeStyle: Hashable {
    let lineWidth: CGFloat
    let opacity: Double
    let isDashed: Bool

    init(
        _ kind: NetworkEdgeKind,
        level: NetworkGraphLevel
    ) {
        isDashed = kind.isDashed
        switch (level, kind) {
        case (.overview, .meToGroup), (.overview, .meToInvitation):
            lineWidth = NetworkGraphMetrics.overviewMeToGroupLineWidth
            opacity = NetworkGraphMetrics.overviewMeToGroupLineOpacity
        case (.overview, .friendToGroup):
            lineWidth = NetworkGraphMetrics.overviewFriendToGroupLineWidth
            opacity = NetworkGraphMetrics.overviewFriendToGroupLineOpacity
        case (_, .meToFriend):
            lineWidth = NetworkGraphMetrics.meToReaderLineWidth
            opacity = NetworkGraphMetrics.meToReaderLineOpacity
        case (_, .meToRequester), (.full, .meToInvitation):
            lineWidth = NetworkGraphMetrics.groupLineWidth
            opacity = 1
        case (.full, .meToGroup), (.full, .friendToGroup):
            lineWidth = NetworkGraphMetrics.groupLineWidth
            opacity = NetworkGraphMetrics.groupLineOpacity
        }
    }

    private init(
        lineWidth: CGFloat,
        opacity: Double,
        isDashed: Bool
    ) {
        self.lineWidth = lineWidth
        self.opacity = opacity
        self.isDashed = isDashed
    }

    /// A line lit by the node touched: full green, 2.5 pt, dashed still if it was (R2).
    var lit: NetworkEdgeStyle {
        .init(lineWidth: NetworkGraphMetrics.litLineWidth, opacity: 1, isDashed: isDashed)
    }

    /// A line the node touched does not light: its width, at 12 % — in place of its own opacity,
    /// not on top of it (R2).
    var dimmed: NetworkEdgeStyle {
        .init(lineWidth: lineWidth, opacity: NetworkGraphMetrics.dimmedLineOpacity, isDashed: isDashed)
    }
}
