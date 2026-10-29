//
//  CoverFlowGeometryTests.swift
//  ReCIT_iOSTests
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite("CoverFlowGeometry")
struct CoverFlowGeometryTests {

    private let geometry: CoverFlowGeometry = .init(coverWidth: 172)

    @Test("The cover at the centre faces the reader, full size and unshaded")
    func centreFacesTheReader() {
        let placement: CoverFlowGeometry.Placement = geometry.placement(distance: 0)

        #expect(placement.angle == 0)
        #expect(placement.offset == 0)
        #expect(placement.scale == 1)
        #expect(placement.shade == 0)
    }

    @Test("Both sides are mirrored")
    func sidesAreMirrored() {
        for distance in [10, 38, 76, 200] as [CGFloat] {
            let left: CoverFlowGeometry.Placement = geometry.placement(distance: -distance)
            let right: CoverFlowGeometry.Placement = geometry.placement(distance: distance)

            #expect(left.angle == -right.angle)
            #expect(left.offset == -right.offset)
            #expect(left.scale == right.scale)
            #expect(left.shade == right.shade)
        }
    }

    @Test("A cover half a pitch away is half turned")
    func halfwayIsHalfTurned() {
        let placement: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.pitch / 2)

        #expect(placement.angle == -CoverFlowGeometry.maxAngle / 2)
        #expect(abs(placement.offset - geometry.push / 2) < 0.001)
    }

    @Test("Turn, push and scale stop growing after one pitch")
    func turnSaturatesAfterOnePitch() {
        let first: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.pitch)
        let third: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.pitch * 3)

        #expect(first.angle == -CoverFlowGeometry.maxAngle)
        #expect(third.angle == -CoverFlowGeometry.maxAngle)
        #expect(first.offset == third.offset)
        #expect(first.scale == CoverFlowGeometry.turnedScale)
        #expect(third.scale == CoverFlowGeometry.turnedScale)
    }

    @Test("The shade deepens with the rank, up to a limit")
    func shadeDeepensThenStops() {
        let ranks: [Double] = [1, 2, 3, 4, 6].map { rank in
            geometry.placement(distance: CoverFlowGeometry.pitch * rank).shade
        }

        #expect(ranks[0] < ranks[1])
        #expect(ranks[1] < ranks[2])
        #expect(ranks[2] < ranks[3])
        #expect(ranks[3] == ranks[4])
    }

    @Test("The first neighbour clears the front cover by the gap")
    func firstNeighbourClearsTheFrontCover() {
        let placement: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.pitch)
        let neighbourCentre: CGFloat = CoverFlowGeometry.pitch + placement.offset
        let neighbourInnerEdge: CGFloat = neighbourCentre - geometry.turnedWidth / 2
        let frontOuterEdge: CGFloat = geometry.coverWidth / 2

        #expect(abs(neighbourInnerEdge - frontOuterEdge - CoverFlowGeometry.gapToFront) < 0.001)
    }
}
