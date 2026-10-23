//
//  NetworkGraphLayout.swift
//  ReCIT_iOS
//
//  Where each node of the Réseau graph goes (PRD 0019, module 6, Q16–Q19). Radial first, then
//  relaxed:
//
//  1. **The readers tied to me alone** — isolated friends and requesters — on a ring close around
//     « Vous » (Q6), in the order of the graph.
//  2. **The groups** on a wider ring, in the order of the graph — admin, member, invitation, each
//     by name — the first on top, then clockwise (Q18).
//  3. **Every other friend** at the middle of their groups, pushed outwards past them. Friends who
//     share exactly the same groups fan out side by side, then in rows further out, so a club of
//     twenty reads as a crowd behind its card rather than a pile.
//  4. **Relaxation** (`NetworkGraphRelaxation`) until no two boxes are closer than `spacing`, then
//     a pass that guarantees it (Q19).
//
//  The rings are ellipses, narrower than tall: the graph opens on a portrait iPhone, and a round
//  network would be framed by the width of the screen with its height left empty.
//
//  **The boxes are measured**, with the real text at the reader's text size (Q19): the layout
//  never guesses a node's size, so a long name or a large text size moves its neighbours rather
//  than covering them.
//
//  **Deterministic** (Q16, Q17): the order comes from the graph, which sorts by name and id; the
//  only « randomness » is a few points of jitter per node, read from its id through
//  `DeterministicTilt` — never `String.hashValue`, which is seeded per process. The same network
//  with the same boxes gives the same positions on every launch, and nothing is persisted.
//
//  **A value**, `Hashable`: it is the fingerprint the placement is cached under (Q45) — the
//  graph's shape and every box, nothing the placement does not read.
//

import CoreGraphics
import Foundation

nonisolated struct NetworkGraphLayout: Hashable, Sendable {

    /// A group on the ring, in the order of the graph.
    nonisolated struct GroupItem: Hashable, Sendable {
        let id: String
        let box: NetworkNodeBox
    }

    /// A reader, in the order of the graph.
    nonisolated struct ReaderItem: Hashable, Sendable {
        let id: String
        let box: NetworkNodeBox
        /// Where in `groups` are the groups a line joins them to.
        let groupOffsets: [Int]
        /// Tied to me alone — an isolated friend or a requester: on the ring around « Vous ».
        let isPeripheral: Bool
    }

    // MARK: - Tuning

    /// The least room between two boxes.
    static let spacing: Double = 10
    /// The rings' width over their height.
    static let aspect: Double = 0.55
    /// How much dearer width is than height when two boxes are pushed apart (see
    /// `NetworkGraphRelaxation.widthCost`).
    static let widthCost: Double = 3
    /// The least height of the groups' ring above « Vous », as drawn in R1.
    static let minimumGroupRadius: Double = 150
    /// How hard a node is pulled back towards its seat in the first passes, and for how many.
    static let pull: Double = 0.06
    static let pullPasses: Int = 120
    /// When relaxation gives up and leaves the rest to the legalisation.
    static let maximumPasses: Int = 200
    /// How far, in points, a node strays from its seat, read from its id.
    static let jitter: Double = 6
    /// The weight of a group against a reader's 1 when two are pushed apart: a group barely
    /// moves, so the ring keeps its order.
    static let groupInverseMass: Double = 0.2

    let me: NetworkNodeBox
    let groups: [GroupItem]
    let readers: [ReaderItem]

    init(
        me: NetworkNodeBox,
        groups: [GroupItem],
        readers: [ReaderItem]
    ) {
        self.me = me
        self.groups = groups
        self.readers = readers
    }

    /// The layout of `graph` with the measured boxes, or `nil` while one is still missing.
    init?(
        graph: NetworkGraph,
        boxes: [NetworkNodeID: NetworkNodeBox]
    ) {
        guard let me = boxes[.me] else { return nil }

        var groups: [GroupItem] = []
        for group in graph.groups {
            guard let box = boxes[.group(group.id)] else { return nil }
            groups.append(.init(id: group.id, box: box))
        }
        var readers: [ReaderItem] = []
        for reader in graph.readers {
            guard let box = boxes[reader.nodeID] else { return nil }
            readers.append(
                .init(
                    id: reader.id,
                    box: box,
                    groupOffsets: graph.groupOffsets(of: reader.id),
                    isPeripheral: reader.isIsolated
                )
            )
        }
        self.init(me: me, groups: groups, readers: readers)
    }

    // MARK: - Placement

    /// Where each node goes, « Vous » at the origin. Pure: call it off the main actor.
    func placement() -> NetworkGraphPlacement {
        let ids: [NetworkNodeID] = [.me] + groups.map { .group($0.id) } + readers.map { .reader($0.id) }
        let boxes: [NetworkNodeBox] = [me] + groups.map(\.box) + readers.map(\.box)
        let seats: [CGPoint?] = seats()

        var relaxation: NetworkGraphRelaxation = .init(
            boxes: boxes,
            positions: seats.map { $0 ?? .zero },
            inverseMass: [0]
                + Array(repeating: Self.groupInverseMass, count: groups.count)
                + Array(repeating: 1, count: readers.count),
            fallbackAngle: ids.map(Self.fallbackAngle),
            spacing: Self.spacing,
            widthCost: Self.widthCost
        )
        relaxation.relax(
            targets: seats,
            pull: Self.pull,
            pullPasses: Self.pullPasses,
            maximumPasses: Self.maximumPasses
        )
        relaxation.legalise(gap: Self.spacing / 2, step: 4)

        var positions: [NetworkNodeID: CGPoint] = [:]
        var frames: [NetworkNodeID: CGRect] = [:]
        for (offset, position) in relaxation.positions.enumerated() {
            positions[ids[offset]] = position
            frames[ids[offset]] = boxes[offset].frame(at: position)
        }
        return .init(positions: positions, frames: frames)
    }

    // MARK: - Seats

    /// Where the rings put each node before relaxation, index by index: « Vous », the groups,
    /// the readers.
    private func seats() -> [CGPoint?] {
        let meRadius: Double = Self.halfDiagonal(me)
        let peripheral: [Int] = readers.indices.filter { readers[$0].isPeripheral }
        let peripheralHalfDiagonal: Double = peripheral.map { Self.halfDiagonal(readers[$0].box) }.max() ?? 0
        let peripheralHalfHeight: Double = peripheral.map { readers[$0].box.height / 2 }.max() ?? 0
        let ellipse: Double = .pi * (1 + Self.aspect)

        var readerSeats: [CGPoint?] = Array(repeating: nil, count: readers.count)

        // 1. Tied to me alone: a ring close around « Vous », starting half a step past the top,
        //    where the first group goes.
        var peripheralRadius: Double = 0
        if peripheral.isEmpty == false {
            let around: Double = peripheral.reduce(0) { total, index in
                total + Self.meanSide(readers[index].box) + Self.spacing
            }
            peripheralRadius = max(meRadius + peripheralHalfDiagonal + Self.spacing, around / ellipse)
            let step: Double = 2 * .pi / Double(peripheral.count)
            for (rank, index) in peripheral.enumerated() {
                let angle: Double = -.pi / 2 + (Double(rank) + 0.5) * step
                readerSeats[index] = jittered(
                    onRing(radius: peripheralRadius, angle: angle),
                    id: readers[index].id
                )
            }
        }

        // 2. The groups: first on top, clockwise — y grows downwards, so clockwise is the way the
        //    angle grows. Clear of « Vous » and of the ring inside, room enough around.
        let groupHalfHeight: Double = groups.map { $0.box.height / 2 }.max() ?? 0
        var groupRadius: Double = max(Self.minimumGroupRadius, me.height - me.anchorY + groupHalfHeight + Self.spacing)
        if peripheral.isEmpty == false {
            groupRadius = max(groupRadius, peripheralRadius + peripheralHalfHeight + groupHalfHeight + Self.spacing)
        }
        let aroundGroups: Double = groups.reduce(0) { total, group in
            total + Self.meanSide(group.box) + Self.spacing
        }
        groupRadius = max(groupRadius, aroundGroups / ellipse)
        let groupSeats: [CGPoint] = groups.indices.map { index in
            onRing(
                radius: groupRadius,
                angle: -.pi / 2 + 2 * .pi * Double(index) / Double(groups.count)
            )
        }

        // 3. Every other friend: past the middle of their groups, side by side with those who
        //    share exactly the same ones.
        let readerHalfDiagonal: Double = readers.map { Self.halfDiagonal($0.box) }.max() ?? 0
        let innerRadius: Double = peripheral.isEmpty
            ? meRadius + readerHalfDiagonal + Self.spacing
            : peripheralRadius + peripheralHalfDiagonal + readerHalfDiagonal + Self.spacing
        var crowds: [[Int]: Crowd] = [:]
        for reader in readers where reader.isPeripheral == false {
            crowds[reader.groupOffsets, default: .init()].add(reader.box)
        }
        var seated: [[Int]: Int] = [:]
        for (index, reader) in readers.enumerated() where reader.isPeripheral == false {
            let rank: Int = seated[reader.groupOffsets, default: 0]
            seated[reader.groupOffsets] = rank + 1
            readerSeats[index] = jittered(
                clusterSeat(
                    reader: reader,
                    rank: rank,
                    crowd: crowds[reader.groupOffsets, default: .init()],
                    groupSeats: groupSeats,
                    innerRadius: innerRadius
                ),
                id: reader.id
            )
        }

        return [CGPoint.zero] + groupSeats.map { Optional($0) } + readerSeats
    }

    /// The seat of a friend joined to groups: past the middle of them, outwards, `rank` of the
    /// `crowd` who share the same groups — three in the first row, one more in each row further
    /// out. A row runs across the way out, so a crowd above its card spreads sideways and a crowd
    /// beside it stacks up.
    private func clusterSeat(
        reader: ReaderItem,
        rank: Int,
        crowd: Crowd,
        groupSeats: [CGPoint],
        innerRadius: Double
    ) -> CGPoint {
        let seats: [CGPoint] = reader.groupOffsets.map { groupSeats[$0] }
        let middle: CGPoint = .init(
            x: seats.reduce(0) { $0 + $1.x } / CGFloat(seats.count),
            y: seats.reduce(0) { $0 + $1.y } / CGFloat(seats.count)
        )

        // Outwards on the ellipse, then bent further towards the vertical: a crowd beside a card
        // on a portrait screen runs out of width long before height. From a middle on « Vous » —
        // two groups facing each other — a direction read from the groups' ids.
        var outX: Double = Double(middle.x) / Self.aspect
        var outY: Double = Double(middle.y)
        let length: Double = (outX * outX + outY * outY).squareRoot()
        if length < 1 {
            let key: String = reader.groupOffsets.map { groups[$0].id }.joined(separator: "|")
            let angle: Double = DeterministicTilt.degrees(for: key, amplitude: 180) * .pi / 180
            outX = cos(angle)
            outY = sin(angle)
        } else {
            outX /= length
            outY /= length
        }
        outX *= Self.aspect * Self.aspect
        let worldLength: Double = (outX * outX + outY * outY).squareRoot()
        outX /= worldLength
        outY /= worldLength
        let alongX: Double = -outY
        let alongY: Double = outX

        // Row and place in the row.
        var row: Int = 0
        var firstOfRow: Int = 0
        var capacity: Int = 3
        while rank >= firstOfRow + capacity {
            firstOfRow += capacity
            row += 1
            capacity += 1
        }
        let inRow: Int = min(capacity, crowd.count - firstOfRow)
        let slot: Double = abs(alongX) * crowd.width + abs(alongY) * crowd.height + Self.spacing
        let rowStep: Double = abs(outX) * crowd.width + abs(outY) * crowd.height + Self.spacing
        let along: Double = (Double(rank - firstOfRow) - Double(inRow - 1) / 2) * slot

        let groupBox: NetworkNodeBox = groups[reader.groupOffsets[0]].box
        let clearance: Double = Self.clearance(between: groupBox, and: reader.box, along: outX, outY)
        let out: Double = clearance + Double(row) * rowStep

        var seatX: Double = Double(middle.x) + outX * out + alongX * along
        var seatY: Double = Double(middle.y) + outY * out + alongY * along

        // Never inside the ring of the readers tied to me alone.
        let radial: Double = ((seatX / Self.aspect) * (seatX / Self.aspect) + seatY * seatY).squareRoot()
        if radial < innerRadius && radial > 0 {
            seatX *= innerRadius / radial
            seatY *= innerRadius / radial
        }
        return .init(x: seatX, y: seatY)
    }

    private func onRing(
        radius: Double,
        angle: Double
    ) -> CGPoint {
        .init(x: radius * Self.aspect * cos(angle), y: radius * sin(angle))
    }

    private func jittered(
        _ point: CGPoint,
        id: String
    ) -> CGPoint {
        .init(
            x: Double(point.x) + DeterministicTilt.degrees(for: id, amplitude: Self.jitter),
            y: Double(point.y) + DeterministicTilt.degrees(for: id + "↕", amplitude: Self.jitter)
        )
    }

    // MARK: - Arithmetic

    private static func halfDiagonal(_ box: NetworkNodeBox) -> Double {
        (box.width * box.width + box.height * box.height).squareRoot() / 2
    }

    /// What a box takes along a ring, on average over the ways it can sit on it.
    private static func meanSide(_ box: NetworkNodeBox) -> Double {
        (box.width + box.height) / 2
    }

    /// How far apart, along the unit direction (`x`, `y`), two boxes centred on the same line
    /// have to be for `spacing` to separate them.
    private static func clearance(
        between lhs: NetworkNodeBox,
        and rhs: NetworkNodeBox,
        along x: Double,
        _ y: Double
    ) -> Double {
        let alongX: Double = abs(x) > 0.000_1 ? ((lhs.width + rhs.width) / 2 + spacing) / abs(x) : .infinity
        let alongY: Double = abs(y) > 0.000_1 ? ((lhs.height + rhs.height) / 2 + spacing) / abs(y) : .infinity
        return min(alongX, alongY)
    }

    /// The way a node on « Vous » is walked out, read from its id.
    private static func fallbackAngle(_ node: NetworkNodeID) -> Double {
        let key: String = switch node {
        case .me: ""
        case .group(let id): "group:" + id
        case .reader(let id): "reader:" + id
        }
        return DeterministicTilt.degrees(for: key, amplitude: 180) * .pi / 180
    }
}
