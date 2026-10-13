//
//  NetworkGraphLevel.swift
//  ReCIT_iOS
//
//  How much of each node the Réseau graph draws (PRD 0019, Q31, R3): in full — avatars with
//  their names, group cards with their detail — or, zoomed out, as an overview — readers as
//  24 pt dots, groups as compact tiles, « Vous » at 70 %.
//
//  **The scale alone decides**, with hysteresis: the overview takes over below ×0.6 of full size
//  and gives way above ×0.7, so a pinch that hovers around one threshold never flickers between
//  the two. The number of nodes only sets the opening frame's scale, which then decides like any
//  other. Both thresholds are to be tuned on a device (Q31): they live here and nowhere else.
//

import CoreGraphics

nonisolated enum NetworkGraphLevel: Hashable, Sendable {
    case full
    case overview

    /// Below this scale, the full graph turns to the overview.
    static let overviewEntryScale: CGFloat = 0.6
    /// Above this scale, the overview turns back to the full graph.
    static let overviewExitScale: CGFloat = 0.7
    /// How large « Vous » is drawn in the overview (R3).
    static let overviewMeScale: CGFloat = 0.7

    /// The level at `scale`, coming from this one: unchanged between the two thresholds.
    func next(at scale: CGFloat) -> NetworkGraphLevel {
        switch self {
        case .full:
            scale < Self.overviewEntryScale ? .overview : .full
        case .overview:
            scale > Self.overviewExitScale ? .full : .overview
        }
    }
}
