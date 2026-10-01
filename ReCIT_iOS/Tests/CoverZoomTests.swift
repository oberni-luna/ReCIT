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

        #expect(zoom.pinching(by: 0.2).scale == 1)

        zoom.endPinch(by: 10)
        #expect(zoom.scale == CoverZoom.maximumPinchScale)
    }

    /// A cover fitted to 400 × 600 on a 400 × 900 screen touches its sides, and fills its height
    /// at ×1.5.
    @Test func fillsAtTheLargerOfTheTwoRatios() {
        var zoom: CoverZoom = .init()
        zoom.measure(fitted: .init(width: 400, height: 600), in: .init(width: 400, height: 900))

        #expect(zoom.fillScale == 1.5)
    }

    @Test func aCoverWithTheScreensProportionsFillsWhenFitted() {
        var zoom: CoverZoom = .init()
        zoom.measure(fitted: .init(width: 400, height: 900), in: .init(width: 400, height: 900))

        #expect(zoom.fillScale == 1)
    }

    @Test func anUnmeasuredCoverKeepsItsFillScale() {
        var zoom: CoverZoom = .init()
        zoom.measure(fitted: .init(width: 400, height: 600), in: .init(width: 400, height: 900))
        zoom.measure(fitted: .zero, in: .init(width: 400, height: 900))

        #expect(zoom.fillScale == 1.5)
    }

    /// A very narrow cover must still be able to fill the screen, even past the pinch limit.
    @Test func aPinchCanReachTheFillScale() {
        var zoom: CoverZoom = .init()
        zoom.measure(fitted: .init(width: 80, height: 900), in: .init(width: 400, height: 900))
        zoom.endPinch(by: 10)

        #expect(zoom.scale == 5)
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

    @Test func aDoubleTapFillsAFittedCover() {
        var zoom: CoverZoom = .init()
        zoom.measure(fitted: .init(width: 400, height: 600), in: .init(width: 400, height: 900))
        zoom.toggle()

        #expect(zoom.scale == 1.5)
        #expect(zoom.offset == .zero)
    }

    @Test func aDoubleTapFitsAFilledCover() {
        var zoom: CoverZoom = .init()
        zoom.measure(fitted: .init(width: 400, height: 600), in: .init(width: 400, height: 900))
        zoom.toggle()
        zoom.toggle()

        #expect(zoom.scale == 1)
    }

    @Test func aDoubleTapFitsACoverZoomedAnywhereElse() {
        var zoom: CoverZoom = .init()
        zoom.measure(fitted: .init(width: 400, height: 600), in: .init(width: 400, height: 900))
        zoom.endPinch(by: 3)
        zoom.endPan(by: .init(width: 12, height: 0))
        zoom.toggle()

        #expect(zoom.scale == 1)
        #expect(zoom.offset == .zero)
    }
}
