//
//  SpineStripLoaderTests.swift
//  ReCIT_iOSTests
//
//  Unit tests for the pure parts of the spine-strip builder: crop geometry and the
//  luminance → title-colour decision. Network-free. See PRD 0002.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite struct SpineStripLoaderTests {

    // MARK: - Crop geometry

    @Test func cropIsLeftmostStripAtFullHeight() {
        let rect = SpineStripLoader.cropRect(imageWidth: 200, imageHeight: 300)
        #expect(rect.origin == .zero)
        #expect(rect.width == CGFloat(SpineStripLoader.stripWidth))
        #expect(rect.height == 300)
    }

    @Test func cropNeverExceedsNarrowImageWidth() {
        let rect = SpineStripLoader.cropRect(imageWidth: 4, imageHeight: 120)
        #expect(rect.width == 4)
        #expect(rect.height == 120)
    }

    // MARK: - Title colour from luminance

    @Test func brightStripUsesDarkTitle() {
        #expect(SpineStripLoader.titleIsDark(luminance: 0.85))
    }

    @Test func darkStripUsesLightTitle() {
        #expect(!SpineStripLoader.titleIsDark(luminance: 0.2))
    }

    @Test func thresholdBoundaryPrefersLightTitle() {
        // At exactly the threshold, not "dark" — a white title is used.
        #expect(!SpineStripLoader.titleIsDark(luminance: SpineStripLoader.darkTitleThreshold))
    }
}
