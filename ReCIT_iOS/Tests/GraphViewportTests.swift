//
//  GraphViewportTests.swift
//  ReCIT_iOSTests
//
//  The camera over the Réseau graph (PRD 0019, module 7). What can be got wrong is arithmetic:
//  an opening frame that is not the whole network, a scale that escapes its range, a pinch that
//  lets the content slide away from the fingers, a drag that loses the network off screen, a
//  touch that picks the wrong node, a node left under the sheet — or moved further than needed;
//  and, since issue 0109, a level that flickers around its threshold, a button that zooms by
//  anything but ×1.5, or a touch in the overview that lands on a box no longer drawn.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite struct GraphViewportTests {

    /// A small network in world points, « Vous » at the origin: a group card to the right, a
    /// friend under me, another up and to the left, and a 24 pt dot far to the left.
    private static let placement: NetworkGraphPlacement = {
        let boxes: [NetworkNodeID: (CGPoint, NetworkNodeBox)] = [
            .me: (.zero, .init(size: .init(width: 72, height: 90), anchor: .init(x: 36, y: 36))),
            .group("club"): (.init(x: 160, y: 0), .init(centred: .init(width: 180, height: 50))),
            .reader("ines"): (.init(x: 0, y: 220), .init(size: .init(width: 100, height: 64), anchor: .init(x: 50, y: 22))),
            .reader("lea"): (.init(x: -120, y: -150), .init(size: .init(width: 100, height: 64), anchor: .init(x: 50, y: 22))),
            .reader("dot"): (.init(x: -150, y: 40), .init(centred: .init(width: 24, height: 24)))
        ]
        return .init(
            positions: boxes.mapValues(\.0),
            frames: boxes.mapValues { $0.1.frame(at: $0.0) }
        )
    }()

    private static let screen: CGSize = .init(width: 393, height: 600)

    private func viewport(size: CGSize = screen) -> GraphViewport {
        .init(placement: Self.placement, size: size)
    }

    private func isClose(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        abs(lhs.x - rhs.x) < 0.001 && abs(lhs.y - rhs.y) < 0.001
    }

    /// The network's box on screen.
    private func networkFrame(_ viewport: GraphViewport) -> CGRect {
        Self.placement.positions.keys.reduce(CGRect.null) { box, node in
            box.union(viewport.screenFrame(of: node) ?? .null)
        }
    }

    // MARK: - Opening frame

    @Test func opensOnTheWholeNetworkWithVousInTheMiddle() {
        let viewport: GraphViewport = viewport()

        // It fits at ×0.6 or more with its nodes shrinking with it: it opens in full.
        #expect(viewport.scale == Self.placement.shrinkingFittingScale(in: Self.screen, margin: GraphViewport.margin))
        #expect(viewport.scale >= NetworkGraphLevel.overviewEntryScale)
        #expect(viewport.level == .full)
        #expect(viewport.origin == .init(x: Self.screen.width / 2, y: Self.screen.height / 2))
        #expect(viewport.isAtOpeningFrame)
        let onScreen: CGRect = .init(origin: .zero, size: Self.screen).insetBy(dx: GraphViewport.margin - 0.01, dy: GraphViewport.margin - 0.01)
        #expect(onScreen.contains(networkFrame(viewport)))
    }

    @Test func worldAndScreenAreInverse() {
        let viewport: GraphViewport = viewport().pinching(by: 1.7, at: .init(x: 100, y: 120))
        let world: CGPoint = .init(x: -42, y: 87)

        #expect(isClose(viewport.worldPoint(at: viewport.screenPoint(of: world)), world))
    }

    @Test func nodesKeepTheirSizeFromFullSizeUp() throws {
        let zoomed: GraphViewport = viewport().pinching(by: 2, at: .init(x: 196, y: 300))
        let frame: CGRect = try #require(zoomed.screenFrame(of: .group("club")))
        let anchor: CGPoint = try #require(zoomed.screenAnchor(of: .group("club")))

        #expect(frame.size == .init(width: 180, height: 50))
        #expect(isClose(.init(x: frame.midX, y: frame.midY), anchor))
    }

    // MARK: - Range

    @Test func theSmallestScaleIsTheOpeningFrameAndTheLargestTwiceFullSize() {
        let viewport: GraphViewport = viewport()

        #expect(viewport.scaleRange.lowerBound == viewport.scale)
        #expect(viewport.scaleRange.upperBound == GraphViewport.maximumScale)
        #expect(GraphViewport.maximumScale == 2)
        #expect(viewport.pinching(by: 0.1, at: .init(x: 196, y: 300)).scale == viewport.scale)
        #expect(viewport.pinching(by: 50, at: .init(x: 196, y: 300)).scale == 2)
    }

    @Test func aPinchBuildsOnTheOneBefore() {
        let start: GraphViewport = viewport()
        let anchor: CGPoint = .init(x: 196, y: 300)
        let twice: GraphViewport = start.pinching(by: 1.2, at: anchor).pinching(by: 1.25, at: anchor)

        #expect(abs(twice.scale - start.scale * 1.5) < 0.0001)
    }

    // MARK: - Pinching

    @Test(arguments: [
        CGPoint(x: 196, y: 300),
        CGPoint(x: 150, y: 250),
        CGPoint(x: 240, y: 340)
    ])
    func thePointUnderTheFingersStaysUnderThem(anchor: CGPoint) {
        let start: GraphViewport = viewport()
        let under: CGPoint = start.worldPoint(at: anchor)
        let pinched: GraphViewport = start.pinching(by: 1.6, at: anchor)

        #expect(pinched.scale > start.scale)
        #expect(isClose(pinched.screenPoint(of: under), anchor))
    }

    @Test func pinchingBackOutReturnsWhereItStarted() {
        let start: GraphViewport = viewport()
        let anchor: CGPoint = .init(x: 180, y: 280)
        let back: GraphViewport = start.pinching(by: 1.6, at: anchor).pinching(by: 1 / 1.6, at: anchor)

        #expect(abs(back.scale - start.scale) < 0.0001)
        #expect(isClose(back.origin, start.origin))
    }

    // MARK: - Panning

    @Test func aDragWithinTheBoundsMovesTheNetworkByAsMuch() {
        let start: GraphViewport = viewport()
        let moved: GraphViewport = start.panning(by: .init(width: 30, height: -40))

        #expect(isClose(moved.origin, .init(x: start.origin.x + 30, y: start.origin.y - 40)))
    }

    @Test(arguments: [
        CGSize(width: 5_000, height: 0),
        CGSize(width: -5_000, height: 0),
        CGSize(width: 0, height: 5_000),
        CGSize(width: -5_000, height: -5_000)
    ])
    func theNetworkNeverLeavesTheScreen(translation: CGSize) {
        for start in [viewport(), viewport().pinching(by: 2, at: .init(x: 196, y: 300))] {
            let dragged: GraphViewport = start.panning(by: translation)
            let frame: CGRect = networkFrame(dragged)

            #expect(frame.minX <= Self.screen.width / 2 + 0.001)
            #expect(frame.maxX >= Self.screen.width / 2 - 0.001)
            #expect(frame.minY <= Self.screen.height / 2 + 0.001)
            #expect(frame.maxY >= Self.screen.height / 2 - 0.001)
        }
    }

    @Test func recentringReturnsToTheOpeningFrame() {
        let opening: GraphViewport = viewport()
        let moved: GraphViewport = opening
            .pinching(by: 1.8, at: .init(x: 80, y: 90))
            .panning(by: .init(width: -60, height: 20))

        #expect(moved.isAtOpeningFrame == false)
        #expect(moved.recentred() == opening)
    }

    // MARK: - Touching

    @Test func aTouchOnANodeLandsOnIt() throws {
        let viewport: GraphViewport = viewport()
        for node in Self.placement.positions.keys {
            let anchor: CGPoint = try #require(viewport.screenAnchor(of: node))
            #expect(viewport.node(at: anchor) == node)
        }
    }

    @Test func aTouchAnywhereOnAGroupCardLandsOnIt() throws {
        let viewport: GraphViewport = viewport()
        let card: CGRect = try #require(viewport.screenFrame(of: .group("club")))

        #expect(viewport.node(at: .init(x: card.maxX - 2, y: card.minY + 2)) == .group("club"))
    }

    /// A 24 pt dot answers within a 44 pt square around its centre, and no further.
    @Test func aSmallNodeAnswersWithin44Points() throws {
        let viewport: GraphViewport = viewport()
        let dot: CGPoint = try #require(viewport.screenAnchor(of: .reader("dot")))

        #expect(viewport.node(at: .init(x: dot.x + 20, y: dot.y - 20)) == .reader("dot"))
        #expect(viewport.node(at: .init(x: dot.x, y: dot.y + 21.9)) == .reader("dot"))
        #expect(viewport.node(at: .init(x: dot.x + 23, y: dot.y)) == nil)
    }

    /// Where two touch zones overlap, the node whose centre is nearer wins.
    @Test func theNearestCentreWins() {
        let boxes: [NetworkNodeID: CGPoint] = [
            .reader("a"): .init(x: 0, y: 0),
            .reader("b"): .init(x: 30, y: 0)
        ]
        let placement: NetworkGraphPlacement = .init(
            positions: boxes,
            frames: boxes.mapValues { NetworkNodeBox(centred: .init(width: 24, height: 24)).frame(at: $0) }
        )
        let viewport: GraphViewport = .init(placement: placement, size: .init(width: 400, height: 400))
        let a: CGPoint = viewport.screenPoint(of: .zero)

        #expect(viewport.node(at: .init(x: a.x + 12, y: a.y)) == .reader("a"))
        #expect(viewport.node(at: .init(x: a.x + 18, y: a.y)) == .reader("b"))
    }

    @Test func aTouchOnEmptySpaceLandsOnNothing() {
        #expect(viewport().node(at: .init(x: 4, y: 596)) == nil)
    }

    // MARK: - The sheet

    @Test func aNodeUnderTheSheetIsLiftedJustClearOfIt() throws {
        let start: GraphViewport = viewport().pinching(by: 1.4, at: .init(x: 196, y: 300))
        let frame: CGRect = try #require(start.screenFrame(of: .reader("ines")))
        let inset: CGFloat = Self.screen.height - frame.maxY + 60
        let revealed: GraphViewport = start.revealing(.reader("ines"), bottomInset: inset)
        let after: CGRect = try #require(revealed.screenFrame(of: .reader("ines")))

        #expect(revealed.scale == start.scale)
        #expect(abs(after.maxY - (Self.screen.height - inset - GraphViewport.margin)) < 0.001)
        #expect(revealed.origin.x == start.origin.x)
    }

    @Test func aNodeAlreadyClearOfTheSheetDoesNotMove() {
        let start: GraphViewport = viewport()

        #expect(start.revealing(.reader("lea"), bottomInset: 200) == start)
        #expect(start.revealing(.reader("ines"), bottomInset: 0) == start)
    }

    // MARK: - Changes

    @Test func aSyncKeepsTheZoomAndThePlace() {
        let zoomed: GraphViewport = viewport()
            .pinching(by: 1.5, at: .init(x: 196, y: 300))
            .panning(by: .init(width: 20, height: 10))
        let updated: GraphViewport = zoomed.updating(placement: Self.placement, size: Self.screen)

        #expect(updated == zoomed)
    }

    @Test func aCameraStillOnItsOpeningFrameFollowsTheNewOne() {
        let small: CGSize = .init(width: 300, height: 400)
        let updated: GraphViewport = viewport().updating(placement: Self.placement, size: small)

        #expect(updated == viewport(size: small))
        #expect(updated.isAtOpeningFrame)
    }

    // MARK: - Below full size

    @Test func belowFullSizeTheNodesShrinkWithTheNetwork() throws {
        let start: GraphViewport = viewport()
        let shrunk: GraphViewport = start.pinching(by: 0.8 / start.scale, at: .init(x: 196, y: 300))
        let frame: CGRect = try #require(shrunk.screenFrame(of: .group("club")))
        let anchor: CGPoint = try #require(shrunk.screenAnchor(of: .group("club")))

        #expect(abs(shrunk.scale - 0.8) < 0.0001)
        #expect(shrunk.level == .full)
        #expect(abs(shrunk.nodeScale - 0.8) < 0.0001)
        #expect(abs(frame.width - 180 * 0.8) < 0.001)
        #expect(abs(frame.height - 50 * 0.8) < 0.001)
        #expect(isClose(.init(x: frame.midX, y: frame.midY), anchor))
    }

    // MARK: - Levels

    /// A network far wider than the screen: it opens well below ×0.6.
    private static let wide: NetworkGraphPlacement = {
        let boxes: [NetworkNodeID: (CGPoint, NetworkNodeBox)] = [
            .me: (.zero, .init(size: .init(width: 72, height: 90), anchor: .init(x: 36, y: 36))),
            .group("club"): (.init(x: 600, y: 0), .init(centred: .init(width: 180, height: 50))),
            .reader("ines"): (.init(x: -600, y: 300), .init(size: .init(width: 100, height: 64), anchor: .init(x: 50, y: 22)))
        ]
        return .init(
            positions: boxes.mapValues(\.0),
            frames: boxes.mapValues { $0.1.frame(at: $0.0) }
        )
    }()

    private func wideViewport() -> GraphViewport {
        .init(placement: Self.wide, size: Self.screen)
    }

    /// The camera pinched to `scale` about the middle of the screen.
    private func pinched(
        _ viewport: GraphViewport,
        to scale: CGFloat
    ) -> GraphViewport {
        viewport.pinching(by: scale / viewport.scale, at: .init(x: Self.screen.width / 2, y: Self.screen.height / 2))
    }

    @Test("The overview takes over below ×0.6 and gives way above ×0.7", arguments: [
        (NetworkGraphLevel.full, CGFloat(0.65), NetworkGraphLevel.full),
        (.full, 0.6, .full),
        (.full, 0.59, .overview),
        (.overview, 0.59, .overview),
        (.overview, 0.65, .overview),
        (.overview, 0.7, .overview),
        (.overview, 0.71, .full),
        (.full, 1.5, .full),
        (.overview, 0.1, .overview)
    ])
    func levelHysteresis(
        from: NetworkGraphLevel,
        scale: CGFloat,
        to: NetworkGraphLevel
    ) {
        #expect(from.next(at: scale) == to)
    }

    @Test func aPinchHoveringAroundAThresholdDoesNotFlicker() {
        let start: GraphViewport = wideViewport()
        #expect(start.scale < NetworkGraphLevel.overviewEntryScale)
        #expect(start.level == .overview)

        // Out of the overview only past ×0.7…
        let hovering: GraphViewport = pinched(start, to: 0.65)
        #expect(hovering.level == .overview)
        #expect(pinched(hovering, to: 0.69).level == .overview)
        let full: GraphViewport = pinched(hovering, to: 0.72)
        #expect(full.level == .full)

        // …and back into it only under ×0.6: back and forth around ×0.65 changes nothing.
        var camera: GraphViewport = full
        for scale: CGFloat in [0.65, 0.68, 0.62, 0.66, 0.61] {
            camera = pinched(camera, to: scale)
            #expect(camera.level == .full)
        }
        #expect(pinched(camera, to: 0.58).level == .overview)
    }

    /// A network that does not fit at ×0.6 opens in the overview, framed on the overview's own
    /// boxes: every dot and tile on screen, at a larger scale than the full boxes would allow.
    @Test func aLargeNetworkOpensOnTheOverviewsBoxes() {
        let overviewBoxes: [NetworkNodeID: NetworkNodeBox] = [
            .me: NetworkNodeBox(size: .init(width: 72, height: 90), anchor: .init(x: 36, y: 36)).scaled(by: 0.7),
            .group("club"): .init(size: .init(width: 86, height: 72), anchor: .init(x: 43, y: 26)),
            .reader("ines"): .init(centred: .init(width: 24, height: 24))
        ]
        let full: GraphViewport = wideViewport()
        let camera: GraphViewport = full.with(overviewBoxes: overviewBoxes)

        #expect(camera.level == .overview)
        #expect(camera.isAtOpeningFrame)
        #expect(camera.scale > full.scale)
        let onScreen: CGRect = .init(origin: .zero, size: Self.screen).insetBy(dx: GraphViewport.margin - 0.01, dy: GraphViewport.margin - 0.01)
        #expect(onScreen.contains(networkFrame(camera)))
        #expect(networkFrame(camera).maxX > Self.screen.width - GraphViewport.margin - 1)
    }

    @Test func aSmallNetworkOpensInFullAndALargeOneInTheOverview() {
        let small: GraphViewport = .init(
            placement: Self.placement,
            size: .init(width: 1_000, height: 1_000)
        )

        #expect(small.scale == 1)
        #expect(small.level == .full)
        #expect(wideViewport().level == .overview)
    }

    @Test func aSyncKeepsTheLevel() {
        let hovering: GraphViewport = pinched(wideViewport(), to: 0.65)
        let updated: GraphViewport = hovering.updating(placement: Self.wide, size: Self.screen)

        #expect(updated.level == .overview)
        #expect(updated == hovering)
    }

    // MARK: - Buttons

    @Test func zoomingInAndOutGoesByOneAndAHalfAboutTheMiddle() {
        let start: GraphViewport = viewport().pinching(by: 1.2, at: .init(x: 196, y: 300))
        let middle: CGPoint = .init(x: Self.screen.width / 2, y: Self.screen.height / 2)
        let underMiddle: CGPoint = start.worldPoint(at: middle)

        let zoomedIn: GraphViewport = start.zoomingIn()
        #expect(abs(zoomedIn.scale - start.scale * 1.5) < 0.0001)
        #expect(isClose(zoomedIn.screenPoint(of: underMiddle), middle))

        let back: GraphViewport = zoomedIn.zoomingOut()
        #expect(abs(back.scale - start.scale) < 0.0001)
        #expect(isClose(back.origin, start.origin))
    }

    @Test func theButtonsStopAtTheEndsOfTheRange() {
        let opening: GraphViewport = viewport()
        #expect(opening.canZoomOut == false)
        #expect(opening.zoomingOut() == opening)
        #expect(opening.canZoomIn)

        var camera: GraphViewport = opening
        for _ in 0..<10 {
            camera = camera.zoomingIn()
        }
        #expect(camera.scale == GraphViewport.maximumScale)
        #expect(camera.canZoomIn == false)
        #expect(camera.canZoomOut)
    }

    @Test func recentringAfterTheButtonsReturnsToTheOpeningFrame() {
        let opening: GraphViewport = wideViewport()
        var moved: GraphViewport = opening
        for _ in 0..<5 {
            moved = moved.zoomingIn()
        }
        moved = moved.panning(by: .init(width: 40, height: -30))

        #expect(moved.level == .full)
        let recentred: GraphViewport = moved.recentred()
        #expect(recentred.isAtOpeningFrame)
        #expect(recentred.scale == opening.scale)
        #expect(recentred.origin == opening.origin)
        #expect(recentred.level == .overview)
    }

    // MARK: - Touching the overview

    /// In the overview, a group is its compact tile: a touch where its full card was, off the
    /// tile, lands on nothing; a reader is a 24 pt dot, touched within 44 pt.
    @Test func aTouchInTheOverviewLandsOnTheBoxesItDraws() throws {
        let overviewBoxes: [NetworkNodeID: NetworkNodeBox] = [
            .me: NetworkNodeBox(size: .init(width: 72, height: 90), anchor: .init(x: 36, y: 36)).scaled(by: 0.7),
            .group("club"): .init(size: .init(width: 86, height: 72), anchor: .init(x: 43, y: 26)),
            .reader("ines"): .init(centred: .init(width: 24, height: 24))
        ]
        let camera: GraphViewport = wideViewport().with(overviewBoxes: overviewBoxes)
        #expect(camera.level == .overview)

        let club: CGPoint = try #require(camera.screenAnchor(of: .group("club")))
        let tile: CGRect = try #require(camera.screenFrame(of: .group("club")))
        #expect(tile.size == .init(width: 86, height: 72))
        #expect(isClose(.init(x: tile.midX, y: tile.minY + 26), club))
        #expect(camera.node(at: .init(x: club.x, y: club.y + 40)) == .group("club"))
        // Inside the full card, 70 pt to the side of its centre, but off the tile: nothing any more.
        #expect(camera.node(at: .init(x: club.x + 70, y: club.y)) == nil)

        let ines: CGPoint = try #require(camera.screenAnchor(of: .reader("ines")))
        #expect(camera.node(at: .init(x: ines.x + 21, y: ines.y)) == .reader("ines"))
        #expect(camera.node(at: .init(x: ines.x, y: ines.y + 30)) == nil)

        // Back in full, the full boxes answer again.
        let full: GraphViewport = pinched(camera, to: 1)
        #expect(full.level == .full)
        let card: CGRect = try #require(full.screenFrame(of: .group("club")))
        #expect(card.size == .init(width: 180, height: 50))
    }
}
