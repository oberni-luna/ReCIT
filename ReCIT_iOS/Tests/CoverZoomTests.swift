//
//  CoverZoomTests.swift
//  ReCIT_iOSTests
//
//  A cover shown full screen can be pinched, dragged and double-tapped. What can be got wrong is
//  the arithmetic between gestures: a scale that escapes its bounds, a pinch that forgets the one
//  before it, a cover left off-centre once it is back at its fitted size.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite struct CoverZoomTests {

    @Test func startsFittedAndCentred() {
        let zoom: CoverZoom = .init()

        #expect(zoom.scale == 1)
        #expect(zoom.offset == .zero)
        #expect(zoom.isZoomed == false)
    }

    @Test func aPinchBuildsOnTheOneBefore() {
        var zoom: CoverZoom = .init()
        zoom.endPinch(by: 2)
        zoom.endPinch(by: 1.5)

        #expect(zoom.scale == 3)
    }

    @Test func theScaleStaysWithinItsRange() {
        var zoom: CoverZoom = .init()

        #expect(zoom.pinching(by: 0.2).scale == CoverZoom.scaleRange.lowerBound)

        zoom.endPinch(by: 10)
        #expect(zoom.scale == CoverZoom.scaleRange.upperBound)
    }

    @Test func aFittedCoverDoesNotMove() {
        let zoom: CoverZoom = .init()

        #expect(zoom.panning(by: .init(width: 40, height: 80)).offset == .zero)
    }

    @Test func aMagnifiedCoverMovesByEachDrag() {
        var zoom: CoverZoom = .init()
        zoom.endPinch(by: 2)
        zoom.endPan(by: .init(width: 10, height: -20))
        zoom.endPan(by: .init(width: 5, height: 5))

        #expect(zoom.offset == .init(width: 15, height: -15))
    }

    @Test func pinchingBackToFitRecentres() {
        var zoom: CoverZoom = .init()
        zoom.endPinch(by: 2)
        zoom.endPan(by: .init(width: 30, height: 30))
        zoom.endPinch(by: 0.4)

        #expect(zoom.isZoomed == false)
        #expect(zoom.offset == .zero)
    }

    @Test func aDoubleTapMagnifiesThenFitsAgain() {
        var zoom: CoverZoom = .init()
        zoom.toggle()
        #expect(zoom.scale == CoverZoom.doubleTapScale)

        zoom.endPan(by: .init(width: 12, height: 0))
        zoom.toggle()
        #expect(zoom == .init())
    }
}
