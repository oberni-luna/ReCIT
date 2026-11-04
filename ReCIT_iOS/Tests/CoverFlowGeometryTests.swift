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
        for distance in [10, 38, 64, 128, 200] as [CGFloat] {
            let left: CoverFlowGeometry.Placement = geometry.placement(distance: -distance)
            let right: CoverFlowGeometry.Placement = geometry.placement(distance: distance)

            #expect(left.angle == -right.angle)
            #expect(left.offset == -right.offset)
            #expect(left.scale == right.scale)
            #expect(left.shade == right.shade)
        }
    }

    @Test("A cover half a step away is half turned")
    func halfwayIsHalfTurned() {
        let placement: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.step / 2)
        let drawnBack: CGFloat = (CoverFlowGeometry.pitch - CoverFlowGeometry.step) / 2

        #expect(placement.angle == -CoverFlowGeometry.maxAngle / 2)
        #expect(abs(placement.offset - drawnBack - geometry.push / 2) < 0.001)
    }

    @Test("Covers past the first are drawn one pitch apart, whatever the step")
    func farCoversKeepThePitch() {
        let second: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.step * 2)
        let third: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.step * 3)
        let secondCentre: CGFloat = CoverFlowGeometry.step * 2 + second.offset
        let thirdCentre: CGFloat = CoverFlowGeometry.step * 3 + third.offset

        #expect(abs(thirdCentre - secondCentre - CoverFlowGeometry.pitch) < 0.001)
    }

    @Test("Turn and scale stop growing after one step")
    func turnSaturatesAfterOneStep() {
        let first: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.step)
        let third: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.step * 3)

        #expect(first.angle == -CoverFlowGeometry.maxAngle)
        #expect(third.angle == -CoverFlowGeometry.maxAngle)
        #expect(first.scale == CoverFlowGeometry.turnedScale)
        #expect(third.scale == CoverFlowGeometry.turnedScale)
    }

    @Test("The shade deepens with the rank, up to a limit")
    func shadeDeepensThenStops() {
        let ranks: [Double] = [1, 2, 3, 4, 6].map { rank in
            geometry.placement(distance: CoverFlowGeometry.step * rank).shade
        }

        #expect(ranks[0] < ranks[1])
        #expect(ranks[1] < ranks[2])
        #expect(ranks[2] < ranks[3])
        #expect(ranks[3] == ranks[4])
    }

    @Test("The first neighbour clears the front cover by the gap")
    func firstNeighbourClearsTheFrontCover() {
        let placement: CoverFlowGeometry.Placement = geometry.placement(distance: CoverFlowGeometry.step)
        let neighbourCentre: CGFloat = CoverFlowGeometry.step + placement.offset
        let neighbourInnerEdge: CGFloat = neighbourCentre - geometry.turnedWidth / 2
        let frontOuterEdge: CGFloat = geometry.coverWidth / 2

        #expect(abs(neighbourInnerEdge - frontOuterEdge - CoverFlowGeometry.gapToFront) < 0.001)
    }
}
