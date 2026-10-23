//
//  NetworkGraphLayoutTests.swift
//  ReCIT_iOSTests
//
//  Where the Réseau graph puts its nodes (PRD 0019, module 6): the same everywhere for the same
//  network, pinned like `DeterministicTilt` so a change of arithmetic cannot re-roll everyone's
//  graph silently; never two boxes over each other, on R1, R3 and a network of 200 friends and
//  30 groups; the groups clockwise from the top in the order of the ring; the readers tied to me
//  alone closer to « Vous » than anyone; and fast enough to keep the screen fluid (Q45).
//

import CoreGraphics
import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("NetworkGraphLayout")
struct NetworkGraphLayoutTests {

    private static let networks: [(String, NetworkGraphInput)] = [
        ("R1", NetworkGraphFixture.r1),
        ("R3", NetworkGraphFixture.r3),
        ("200 + 30", NetworkGraphFixture.stress)
    ]

    private func placement(_ input: NetworkGraphInput) throws -> (NetworkGraph, NetworkGraphPlacement) {
        let graph: NetworkGraph = .init(input)
        let layout: NetworkGraphLayout = try #require(
            NetworkGraphLayout(graph: graph, boxes: NetworkGraphFixture.boxes(for: graph))
        )
        return (graph, layout.placement())
    }

    /// The angle of `point` seen from « Vous », from the top, growing clockwise, in `0..<2π`.
    private func clockwiseAngle(_ point: CGPoint) -> Double {
        let angle: Double = atan2(Double(point.x), -Double(point.y))
        return angle < 0 ? angle + 2 * .pi : angle
    }

    private func distance(_ point: CGPoint) -> Double {
        (Double(point.x * point.x + point.y * point.y)).squareRoot()
    }

    /// How far `point` is from « Vous » on the layout's rings, which are narrower than tall.
    private func ringDistance(_ point: CGPoint) -> Double {
        distance(.init(x: Double(point.x) / NetworkGraphLayout.aspect, y: Double(point.y)))
    }

    // MARK: - Determinism

    @Test("The same network with the same boxes lands in the same places")
    func sameInputSamePlacement() throws {
        let (_, first) = try placement(NetworkGraphFixture.r3)
        let (_, second) = try placement(NetworkGraphFixture.r3)

        #expect(first == second)
    }

    /// The hard-coded values pin the whole chain — seats, jitter, relaxation — across launches:
    /// a process-seeded hash would pass the test above and fail this one on the next run, and a
    /// change of arithmetic would move everyone's graph without a word. Change them only on
    /// purpose.
    @Test("R1 lands where it always has, from one launch to the next")
    func pinnedAcrossLaunches() throws {
        let (_, placement) = try placement(NetworkGraphFixture.r1)
        let pinned: [(NetworkNodeID, CGFloat, CGFloat)] = [
            (.me, 0, 0),
            (.group("club"), 0, -169.3913),
            (.group("bd"), 81.0873, 83.0007),
            (.group("l11"), -81.0873, 143.0107),
            (.reader("ariane"), 68.0028, 0.5520),
            (.reader("paul"), -68.0019, 3.7500),
            (.reader("ines"), -29.4346, -245.3947),
            (.reader("hugo"), 151.5055, 140.0101),
            (.reader("sami"), 80.6600, 174.8330)
        ]

        for (node, x, y) in pinned {
            let position: CGPoint = try #require(placement.position(of: node))
            #expect(abs(position.x - x) < 0.01, "\(node): x \(position.x)")
            #expect(abs(position.y - y) < 0.01, "\(node): y \(position.y)")
        }
    }

    @Test("« Vous » is the origin")
    func meAtTheOrigin() throws {
        for (_, input) in Self.networks {
            let (_, placement) = try placement(input)
            #expect(placement.position(of: .me) == .zero)
        }
    }

    // MARK: - Overlap

    @Test("No two boxes overlap", arguments: networks.map(\.0))
    func zeroOverlap(network: String) throws {
        let input: NetworkGraphInput = try #require(Self.networks.first { $0.0 == network }?.1)
        let (graph, placement) = try placement(input)
        let frames: [CGRect] = try graph.nodes.map { try #require(placement.frame(of: $0)) }

        var overlaps: Int = 0
        for first in frames.indices {
            for second in frames.indices where second > first {
                let shared: CGRect = frames[first].intersection(frames[second])
                if shared.isNull == false && shared.width > 0.001 && shared.height > 0.001 {
                    overlaps += 1
                }
            }
        }
        #expect(overlaps == 0)
    }

    @Test("Every node keeps its measured box")
    func boxesKeepTheirSize() throws {
        let (graph, placement) = try placement(NetworkGraphFixture.r1)
        let boxes: [NetworkNodeID: NetworkNodeBox] = NetworkGraphFixture.boxes(for: graph)

        for node in graph.nodes {
            let frame: CGRect = try #require(placement.frame(of: node))
            let box: NetworkNodeBox = try #require(boxes[node])
            let position: CGPoint = try #require(placement.position(of: node))
            #expect(frame == box.frame(at: position))
        }
    }

    // MARK: - The ring

    @Test("Groups in the order of the ring: the first on top, then clockwise", arguments: networks.map(\.0))
    func groupOrder(network: String) throws {
        let input: NetworkGraphInput = try #require(Self.networks.first { $0.0 == network }?.1)
        let (graph, placement) = try placement(input)
        let angles: [Double] = try graph.groups.map { try clockwiseAngle(#require(placement.position(of: .group($0.id)))) }
        let first: CGPoint = try #require(placement.position(of: .group(graph.groups[0].id)))

        #expect(first.y < 0)
        // The first one may sit just left of the top; every next one further round.
        var unwrapped: [Double] = angles
        if unwrapped[0] > .pi {
            unwrapped[0] -= 2 * .pi
        }
        #expect(zip(unwrapped, unwrapped.dropFirst()).allSatisfy { $0 < $1 }, "\(unwrapped)")
    }

    /// Measured on the rings, which are narrower than tall: the ring of the readers tied to me
    /// alone is inside every other.
    @Test("Readers tied to me alone are closer to « Vous » than any reader joined to a group", arguments: networks.map(\.0))
    func isolatedCloser(network: String) throws {
        let input: NetworkGraphInput = try #require(Self.networks.first { $0.0 == network }?.1)
        let (graph, placement) = try placement(input)
        let isolated: [Double] = try graph.readers.filter(\.isIsolated).map { try ringDistance(#require(placement.position(of: $0.nodeID))) }
        let joined: [Double] = try graph.readers.filter { $0.isIsolated == false }.map { try ringDistance(#require(placement.position(of: $0.nodeID))) }

        let farthestIsolated: Double = try #require(isolated.max())
        let nearestJoined: Double = try #require(joined.min())
        #expect(farthestIsolated < nearestJoined)
    }

    @Test("A friend is placed nearer their own group than the group across the ring")
    func friendsNearTheirGroups() throws {
        let (_, placement) = try placement(NetworkGraphFixture.r1)
        let hugo: CGPoint = try #require(placement.position(of: .reader("hugo")))
        let bd: CGPoint = try #require(placement.position(of: .group("bd")))
        let club: CGPoint = try #require(placement.position(of: .group("club")))
        let l11: CGPoint = try #require(placement.position(of: .group("l11")))

        let toBD: Double = distance(.init(x: hugo.x - bd.x, y: hugo.y - bd.y))
        #expect(toBD < distance(.init(x: hugo.x - club.x, y: hugo.y - club.y)))
        #expect(toBD < distance(.init(x: hugo.x - l11.x, y: hugo.y - l11.y)))
    }

    // MARK: - Missing boxes

    @Test("No layout while a node is not measured yet")
    func missingBox() {
        let graph: NetworkGraph = .init(NetworkGraphFixture.r1)
        var boxes: [NetworkNodeID: NetworkNodeBox] = NetworkGraphFixture.boxes(for: graph)
        boxes[.reader("paul")] = nil

        #expect(NetworkGraphLayout(graph: graph, boxes: boxes) == nil)
    }

    // MARK: - Budget

    /// Q45: placed off the main actor, but a placement that takes long leaves « Tout » blank.
    /// Measured on 2026-10-13: 7 ms optimised; 0.4 s unoptimised alone, 1.0 to 1.5 s in this
    /// unoptimised test build alongside the other suites, 2.8 s at worst. The budget is about five
    /// times the usual, so a slower machine does not fail it and a placement gone quadratic does.
    @Test("200 friends and 30 groups are placed within the budget")
    func budget() throws {
        let layout: NetworkGraphLayout = try #require(NetworkGraphFixture.layout(NetworkGraphFixture.stress))
        let clock: ContinuousClock = .init()

        let elapsed: Duration = clock.measure {
            _ = layout.placement()
        }
        #expect(elapsed < .seconds(8))
    }

    // MARK: - Opening frame

    @Test("A small network opens at full size, « Vous » in the middle")
    func fitsAtFullSize() throws {
        let (_, placement) = try placement(NetworkGraphFixture.r1)

        #expect(placement.fittingScale(in: .init(width: 2_000, height: 2_000), margin: 16) == 1)
    }

    @Test("A network larger than the screen opens scaled down, every box on screen", arguments: networks.map(\.0))
    func fitsTheScreen(network: String) throws {
        let input: NetworkGraphInput = try #require(Self.networks.first { $0.0 == network }?.1)
        let (graph, placement) = try placement(input)
        let viewport: CGSize = .init(width: 393, height: 600)
        let margin: CGFloat = 16
        let scale: CGFloat = placement.fittingScale(in: viewport, margin: margin)

        #expect(scale <= 1)
        #expect(scale > NetworkGraphPlacement.minimumScale)
        let screen: CGRect = .init(origin: .zero, size: viewport).insetBy(dx: margin - 0.01, dy: margin - 0.01)
        for node in graph.nodes {
            let position: CGPoint = try #require(placement.position(of: node))
            let frame: CGRect = try #require(placement.frame(of: node))
            let onScreen: CGRect = frame.offsetBy(
                dx: position.x * scale - position.x + viewport.width / 2,
                dy: position.y * scale - position.y + viewport.height / 2
            )
            #expect(screen.contains(onScreen), "\(node)")
        }
    }

    // MARK: - Cache

    @Test("The cache gives back what it computed, and drops the oldest past its capacity")
    func cache() throws {
        let cache: NetworkGraphLayoutCache = .init(capacity: 2)
        let r1: NetworkGraphLayout = try #require(NetworkGraphFixture.layout(NetworkGraphFixture.r1))
        let r3: NetworkGraphLayout = try #require(NetworkGraphFixture.layout(NetworkGraphFixture.r3))
        let other: NetworkGraphLayout = try #require(
            NetworkGraphFixture.layout(
                .init(
                    me: .init(id: "me", username: "me"),
                    friends: [NetworkGraphFixture.reader("lea", "Léa")],
                    requesters: [],
                    groups: []
                )
            )
        )

        #expect(cache.cachedPlacement(for: r1) == nil)
        let computed: NetworkGraphPlacement = cache.placement(for: r1)
        #expect(computed == r1.placement())
        #expect(cache.cachedPlacement(for: r1) == computed)

        _ = cache.placement(for: r3)
        _ = cache.placement(for: other)
        #expect(cache.count == 2)
        #expect(cache.cachedPlacement(for: r1) == nil)
        #expect(cache.cachedPlacement(for: other) != nil)
    }

    @Test("Off the main actor, the same placement")
    func offMainActor() async throws {
        let cache: NetworkGraphLayoutCache = .init()
        let layout: NetworkGraphLayout = try #require(NetworkGraphFixture.layout(NetworkGraphFixture.r1))

        let placement: NetworkGraphPlacement = await cache.placementOffMainActor(for: layout)
        #expect(placement == layout.placement())
    }
}
