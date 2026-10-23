//
//  NetworkNodeBox.swift
//  ReCIT_iOS
//
//  The room a node of the Réseau graph takes — measured from the view, with its real text and at
//  the reader's text size (PRD 0019, Q19) — and its **anchor**: the point the lines meet and the
//  placement puts where it decides. The centre of the avatar for « Vous » and for a reader, whose
//  name hangs under it; the centre of the card for a group.
//
//  Stored as numbers rather than `CGSize` and `CGPoint`, which are not `Hashable`: a box is part
//  of the fingerprint the placement is cached under (Q45).
//

import CoreGraphics

nonisolated struct NetworkNodeBox: Hashable, Sendable {
    let width: Double
    let height: Double
    /// The anchor, from the box's top-left corner.
    let anchorX: Double
    let anchorY: Double

    init(
        size: CGSize,
        anchor: CGPoint
    ) {
        width = size.width
        height = size.height
        anchorX = anchor.x
        anchorY = anchor.y
    }

    /// A box anchored at its centre — a group card.
    init(centred size: CGSize) {
        self.init(
            size: size,
            anchor: .init(x: size.width / 2, y: size.height / 2)
        )
    }

    var size: CGSize {
        .init(width: width, height: height)
    }

    var anchor: CGPoint {
        .init(x: anchorX, y: anchorY)
    }

    /// The box drawn at `factor` of its size, about its anchor — which stays where it was on the
    /// node.
    func scaled(by factor: CGFloat) -> NetworkNodeBox {
        .init(
            size: .init(width: width * factor, height: height * factor),
            anchor: .init(x: anchorX * factor, y: anchorY * factor)
        )
    }

    /// The box when its anchor sits at `position`.
    func frame(at position: CGPoint) -> CGRect {
        .init(
            x: position.x - anchorX,
            y: position.y - anchorY,
            width: width,
            height: height
        )
    }
}
