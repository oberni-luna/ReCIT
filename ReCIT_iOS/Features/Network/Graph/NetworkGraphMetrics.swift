//
//  NetworkGraphMetrics.swift
//  ReCIT_iOS
//
//  The sizes of the Réseau graph that have no design token: the Figma components of the
//  `Réseau · Graphe` section were drawn at sizes the token scale does not hold, and PRD 0019
//  keeps them here rather than adding tokens (precedents: `ShelfCardMetrics`, `SortGridMetrics`).
//
//  « Vous » is `Graph / Me` (`512:16006`), a friend `Graph / Friend` (`512:16016`), a group
//  `Graph / Group` (`512:16061`); the lines are R1′ (`603:20944`) with Q32 and Q32 bis.
//

import SwiftUI

enum NetworkGraphMetrics {

    // MARK: « Vous »

    /// The side of my avatar at the centre of the graph.
    static let meSide: CGFloat = 72
    /// The ring around it, painted over the photo's edge.
    static let meRingWidth: CGFloat = 3
    /// How far the « Vous » pill climbs over the bottom of the avatar.
    static let meLabelOverlap: CGFloat = 10
    /// The « Vous » pill's padding: 3 above and below, 10 on the sides — off the 2 / 4 / 8 / 12
    /// spacing scale.
    static let meLabelInsets: EdgeInsets = .init(
        top: 3,
        leading: 10,
        bottom: 3,
        trailing: 10
    )

    // MARK: A reader

    /// The side of a friend's avatar.
    static let friendSide: CGFloat = 44
    /// The widest a friend's name gets before it is cut, at the default text size — the column
    /// `Graph / Friend` is drawn in. It grows with the text, up to the graph's cap.
    static let friendNameMaxWidth: CGFloat = 100
    /// The hairline around a friend's avatar.
    static let friendRingWidth: CGFloat = 1
    /// The dashed ring of a reader who asked to be my friend (Q5b).
    static let requesterRingWidth: CGFloat = 1.5

    // MARK: The overview (R3)

    /// The side of a reader's dot — `Graph / Friend · Dot` (`519:16390`): no name, no initials
    /// (Q37).
    static let dotSide: CGFloat = 24
    /// The side of a group's tile — `Graph / Group · Compact` (`519:16401`).
    static let compactTileSide: CGFloat = 52
    /// The tile's edge, in `backgroundTintedInverse`.
    static let compactTileBorderWidth: CGFloat = 2
    /// The widest a compact group's name gets before it is cut, at the default text size: R3's
    /// longest, « BD & romans graphiques », fits.
    static let compactNameMaxWidth: CGFloat = 130

    // MARK: A group

    /// The side of a group's picture on its card.
    static let groupTileSide: CGFloat = 32
    /// The widest a group's name or detail gets before it is cut, at the default text size.
    static let groupTextMaxWidth: CGFloat = 160
    /// The card's padding: 8 around, 12 after the text — `spacing/small` and `spacing/s-medium`.
    static let groupCardInsets: EdgeInsets = .init(
        top: DesignSystem.Spacing.small.rawValue,
        leading: DesignSystem.Spacing.small.rawValue,
        bottom: DesignSystem.Spacing.small.rawValue,
        trailing: DesignSystem.Spacing.sMedium.rawValue
    )
    /// The border of a card I administer or belong to.
    static let groupBorderWidth: CGFloat = 1
    /// The dashed border of a card that invited me.
    static let invitedBorderWidth: CGFloat = 1.5

    // MARK: Lines

    /// The one dash of the graph, on lines, invited cards and requester rings alike (Q32).
    static let dash: [CGFloat] = [4, 4]
    /// A line to a group, from me or from a friend, and the dashed lines.
    static let groupLineWidth: CGFloat = 1.5
    static let groupLineOpacity: Double = 0.6
    /// A line from me to a friend: lighter, so the groups carry the drawing (Q32 bis).
    static let meToReaderLineWidth: CGFloat = 1
    static let meToReaderLineOpacity: Double = 0.3
    /// In the overview (R3): a line from me to a group, solid or dashed, is bolder, so the ring
    /// of groups reads at a glance; a line from a friend to a group is lighter, so forty of them
    /// stay a texture.
    static let overviewMeToGroupLineWidth: CGFloat = 2
    static let overviewMeToGroupLineOpacity: Double = 0.8
    static let overviewFriendToGroupLineWidth: CGFloat = 1
    static let overviewFriendToGroupLineOpacity: Double = 0.3

    // MARK: A node touched

    /// What a node not lit by the selection fades to (R2).
    static let dimmedNodeOpacity: Double = 0.3
    /// What a line not lit by the selection fades to — replacing its own opacity, not on top of
    /// it: under a node at 30 %, a line at 30 % would still read as a path (R2).
    static let dimmedLineOpacity: Double = 0.12
    /// A line lit by the selection, at full strength (R2).
    static let litLineWidth: CGFloat = 2.5
    /// The ring of a lit reader — `Graph / Friend · Highlighted` (`512:16012`).
    static let highlightedFriendRingWidth: CGFloat = 2
    /// How long the graph takes to light up or fade when a node is touched.
    static let selectionDuration: TimeInterval = 0.2

    // MARK: The sheet

    /// The avatars of the friends a group's sheet names (`sheet · groupe`, `522:16837`).
    static let sheetAvatarSide: CGFloat = 32
    /// The white ring that keeps two overlapping avatars apart.
    static let sheetAvatarRingWidth: CGFloat = 2
    /// From one avatar to the next: 8 pt of each covered by the one after it.
    static let sheetAvatarStep: CGFloat = 24
    /// The sheet's detent before its content has been measured: a guess near R2's, replaced on the
    /// first layout.
    static let sheetPlaceholderHeight: CGFloat = 200

    // MARK: The controls

    /// The status pill's padding: 6 above and below — off the spacing scale — and 12 on the sides
    /// (`compteur`, `521:15993`).
    static let statusInsets: EdgeInsets = .init(
        top: 6,
        leading: DesignSystem.Spacing.sMedium.rawValue,
        bottom: 6,
        trailing: DesignSystem.Spacing.sMedium.rawValue
    )

    // MARK: The whole

    /// The largest text size the graph follows (Q43). Past it the boxes would crowd the screen;
    /// the lists and VoiceOver carry the larger sizes.
    static let largestTextSize: DynamicTypeSize = .xxxLarge
    /// How long nodes take to slide to their new places when the network changes (Q17).
    static let transitionDuration: TimeInterval = 0.45
}
