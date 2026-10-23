//
//  NetworkOverviewBoxes.swift
//  ReCIT_iOS
//
//  The room each node of the Réseau graph takes on screen in the overview (R3, Q31), its anchor
//  where the lines meet — what the camera's hit test and bounds use while the overview is up:
//
//  - « Vous », its full box at 70 %;
//  - a reader, a 24 pt dot, anchored at its centre;
//  - a group, its compact tile and name as last measured, anchored at the centre of the tile —
//    or the bare tile until it has been measured once.
//

import CoreGraphics

enum NetworkOverviewBoxes {
    static func boxes(
        graph: NetworkGraph,
        fullBoxes: [NetworkNodeID: NetworkNodeBox],
        tileSizes: [NetworkNodeID: CGSize]
    ) -> [NetworkNodeID: NetworkNodeBox] {
        var boxes: [NetworkNodeID: NetworkNodeBox] = [:]
        if let me = fullBoxes[.me] {
            boxes[.me] = me.scaled(by: NetworkGraphLevel.overviewMeScale)
        }
        let tileSide: CGFloat = NetworkGraphMetrics.compactTileSide
        for group in graph.groups {
            let node: NetworkNodeID = .group(group.id)
            let size: CGSize = tileSizes[node] ?? .init(width: tileSide, height: tileSide)
            boxes[node] = .init(
                size: size,
                anchor: .init(x: size.width / 2, y: tileSide / 2)
            )
        }
        let dotSide: CGFloat = NetworkGraphMetrics.dotSide
        for reader in graph.readers {
            boxes[reader.nodeID] = .init(centred: .init(width: dotSide, height: dotSide))
        }
        return boxes
    }
}
