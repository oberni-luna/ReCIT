//
//  NetworkGraphRelaxation.swift
//  ReCIT_iOS
//
//  The second half of the Réseau graph's placement: boxes seeded on their rings are pushed apart
//  until none touches another, then a last pass makes sure of it (PRD 0019, Q16, Q19).
//
//  **Relaxation.** Each pass sweeps the boxes from left to right and separates every pair closer
//  than `spacing`, along the axis where they overlap least, each moving by the inverse of its
//  weight: « Vous » never moves, a group barely, a reader freely. For the first passes every node
//  is also pulled back towards where the rings put it, so that a reader stays near its groups;
//  then the pull stops and the pushing goes on until a pass finds nothing to push.
//
//  **Legalisation.** Relaxation settles almost always, but « almost » is not a guarantee. So the
//  nodes are then taken in order — « Vous », the groups, the readers — and each is walked outwards
//  from « Vous » until it touches none of those before it. Walking outwards always ends: past the
//  last box there is room. That pass is what makes « zero overlap » a property rather than a hope.
//
//  Deterministic: arrays in index order, an insertion sort with an index tie-break, and no set or
//  dictionary walked — the same boxes give the same positions in every process.
//

import CoreGraphics
import Foundation

nonisolated struct NetworkGraphRelaxation {
    /// The anchors, index by index.
    private(set) var x: [Double]
    private(set) var y: [Double]
    private let width: [Double]
    private let height: [Double]
    /// From the anchor to the centre of the box.
    private let centreX: [Double]
    private let centreY: [Double]
    private let inverseMass: [Double]
    /// The direction, in radians, a node is walked out along when it sits on « Vous ».
    private let fallbackAngle: [Double]
    /// The least room between two boxes once relaxed.
    let spacing: Double
    /// How much dearer a point of width is than a point of height when two **wide** boxes — group
    /// cards — collide: side by side, they are staggered up and down rather than spread apart
    /// until the overlap across is this many times the overlap along. The screen is a portrait
    /// one; height is what it has to spare. Boxes about as tall as wide — readers, « Vous » — are
    /// separated by the smaller overlap, whatever its axis.
    let widthCost: Double

    init(
        boxes: [NetworkNodeBox],
        positions: [CGPoint],
        inverseMass: [Double],
        fallbackAngle: [Double],
        spacing: Double,
        widthCost: Double = 1
    ) {
        x = positions.map { Double($0.x) }
        y = positions.map { Double($0.y) }
        width = boxes.map(\.width)
        height = boxes.map(\.height)
        centreX = boxes.map { $0.width / 2 - $0.anchorX }
        centreY = boxes.map { $0.height / 2 - $0.anchorY }
        self.inverseMass = inverseMass
        self.fallbackAngle = fallbackAngle
        self.spacing = spacing
        self.widthCost = widthCost
    }

    var positions: [CGPoint] {
        zip(x, y).map { CGPoint(x: $0, y: $1) }
    }

    // MARK: - Relaxation

    /// Pushes apart every pair of boxes closer than `spacing`; while `pullPasses` last, pulls each
    /// node with a target back towards it, less at every pass.
    ///
    /// - Returns: How many passes it took, `maximumPasses` when it did not settle.
    @discardableResult
    mutating func relax(
        targets: [CGPoint?],
        pull: Double,
        pullPasses: Int,
        maximumPasses: Int
    ) -> Int {
        let count: Int = x.count
        var order: [Int] = Array(0..<count)
        for pass in 0..<maximumPasses {
            if pass < pullPasses {
                let strength: Double = pull * (1 - Double(pass) / Double(pullPasses))
                for index in 0..<count where inverseMass[index] > 0 {
                    guard let target = targets[index] else { continue }

                    x[index] += (Double(target.x) - x[index]) * strength
                    y[index] += (Double(target.y) - y[index]) * strength
                }
            }

            sortByLeftEdge(&order)
            var pushed: Bool = false
            for first in 0..<count {
                let lhs: Int = order[first]
                for second in (first + 1)..<count {
                    let rhs: Int = order[second]
                    // Sorted by left edge: once one starts past this box's right edge and the
                    // spacing, so do all the next ones.
                    if left(rhs) >= right(lhs) + spacing {
                        break
                    }
                    if separate(lhs, rhs) {
                        pushed = true
                    }
                }
            }
            if pushed == false && pass >= pullPasses {
                return pass + 1
            }
        }
        return maximumPasses
    }

    // MARK: - Legalisation

    /// Takes the nodes in index order and walks each outwards from the origin, `step` at a time,
    /// until it is at least `gap` away from every node before it.
    mutating func legalise(
        gap: Double,
        step: Double
    ) {
        for index in x.indices {
            var steps: Int = 0
            while firstOverlap(of: index, before: index, gap: gap) != nil && steps < 100_000 {
                let length: Double = (x[index] * x[index] + y[index] * y[index]).squareRoot()
                if length < 0.000_1 {
                    x[index] += cos(fallbackAngle[index]) * step
                    y[index] += sin(fallbackAngle[index]) * step
                } else {
                    x[index] += x[index] / length * step
                    y[index] += y[index] / length * step
                }
                steps += 1
            }
        }
    }

    /// Whether any two boxes are closer than `gap` — for the tests, which ask it with no gap.
    func hasOverlap(gap: Double) -> Bool {
        x.indices.contains { firstOverlap(of: $0, before: $0, gap: gap) != nil }
    }

    // MARK: - Geometry

    private func left(_ index: Int) -> Double {
        x[index] + centreX[index] - width[index] / 2
    }

    private func right(_ index: Int) -> Double {
        x[index] + centreX[index] + width[index] / 2
    }

    /// The first node among `0..<end` closer than `gap` to `index`.
    private func firstOverlap(
        of index: Int,
        before end: Int,
        gap: Double
    ) -> Int? {
        let centreXOfIndex: Double = x[index] + centreX[index]
        let centreYOfIndex: Double = y[index] + centreY[index]
        for other in 0..<end {
            let reachX: Double = (width[index] + width[other]) / 2 + gap
            let reachY: Double = (height[index] + height[other]) / 2 + gap
            if abs(x[other] + centreX[other] - centreXOfIndex) < reachX
                && abs(y[other] + centreY[other] - centreYOfIndex) < reachY {
                return other
            }
        }
        return nil
    }

    /// Moves `lhs` and `rhs` apart along the axis of least overlap, by their weights, when they
    /// are closer than `spacing`.
    private mutating func separate(
        _ lhs: Int,
        _ rhs: Int
    ) -> Bool {
        let weight: Double = inverseMass[lhs] + inverseMass[rhs]
        guard weight > 0 else { return false }

        let deltaX: Double = (x[rhs] + centreX[rhs]) - (x[lhs] + centreX[lhs])
        let deltaY: Double = (y[rhs] + centreY[rhs]) - (y[lhs] + centreY[lhs])
        let overlapX: Double = (width[lhs] + width[rhs]) / 2 + spacing - abs(deltaX)
        let overlapY: Double = (height[lhs] + height[rhs]) / 2 + spacing - abs(deltaY)
        guard overlapX > 0, overlapY > 0 else { return false }

        // A hair more than the overlap, so that rounding never leaves the pair touching.
        let lhsShare: Double = inverseMass[lhs] / weight
        let rhsShare: Double = inverseMass[rhs] / weight
        let cost: Double = width[lhs] > height[lhs] * 1.5 && width[rhs] > height[rhs] * 1.5 ? widthCost : 1
        if overlapX * cost < overlapY {
            let push: Double = (overlapX + 0.01) * direction(deltaX, lhs, rhs)
            x[lhs] -= push * lhsShare
            x[rhs] += push * rhsShare
        } else {
            let push: Double = (overlapY + 0.01) * direction(deltaY, lhs, rhs)
            y[lhs] -= push * lhsShare
            y[rhs] += push * rhsShare
        }
        return true
    }

    /// Which way `rhs` goes from `lhs`: the way it already lies, or — dead level — by index.
    private func direction(
        _ delta: Double,
        _ lhs: Int,
        _ rhs: Int
    ) -> Double {
        if delta > 0 { return 1 }
        if delta < 0 { return -1 }
        return rhs > lhs ? 1 : -1
    }

    /// An insertion sort by left edge, index breaking ties: from one pass to the next the order
    /// barely changes, so it is close to linear, and it never depends on anything but the boxes.
    private func sortByLeftEdge(_ order: inout [Int]) {
        guard order.count > 1 else { return }

        for current in 1..<order.count {
            let moving: Int = order[current]
            let movingLeft: Double = left(moving)
            var slot: Int = current
            while slot > 0 {
                let previous: Int = order[slot - 1]
                let previousLeft: Double = left(previous)
                if previousLeft > movingLeft || (previousLeft == movingLeft && previous > moving) {
                    order[slot] = previous
                    slot -= 1
                } else {
                    break
                }
            }
            order[slot] = moving
        }
    }
}
