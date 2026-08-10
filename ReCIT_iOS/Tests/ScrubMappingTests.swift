//
//  ScrubMappingTests.swift
//  ReCIT_iOSTests
//
//  Unit tests for the pure scrub position → book index mapping. No UIKit. See PRD 0002.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite struct ScrubMappingTests {

    private let width: CGFloat = 300
    private let height: CGFloat = 180

    @Test func leftEdgeSelectsFirst() {
        #expect(ScrubMapping.index(x: 0, y: 10, width: width, height: height, count: 5) == 0)
    }

    @Test func middleSelectsMiddle() {
        // 5 books over 300pt → 60pt slots; x=150 → slot index 2.
        #expect(ScrubMapping.index(x: 150, y: 10, width: width, height: height, count: 5) == 2)
    }

    @Test func rightEdgeClampsToLast() {
        #expect(ScrubMapping.index(x: width, y: 10, width: width, height: height, count: 5) == 4)
    }

    @Test func outsideHorizontallyIsNil() {
        #expect(ScrubMapping.index(x: -1, y: 10, width: width, height: height, count: 5) == nil)
        #expect(ScrubMapping.index(x: width + 1, y: 10, width: width, height: height, count: 5) == nil)
    }

    @Test func outsideVerticallyIsNil() {
        #expect(ScrubMapping.index(x: 100, y: -1, width: width, height: height, count: 5) == nil)
        #expect(ScrubMapping.index(x: 100, y: height + 1, width: width, height: height, count: 5) == nil)
    }

    @Test func noBooksIsNil() {
        #expect(ScrubMapping.index(x: 50, y: 10, width: width, height: height, count: 0) == nil)
    }

    @Test func singleBookAlwaysSelectsZero() {
        #expect(ScrubMapping.index(x: 0, y: 10, width: width, height: height, count: 1) == 0)
        #expect(ScrubMapping.index(x: width, y: 10, width: width, height: height, count: 1) == 0)
    }
}
