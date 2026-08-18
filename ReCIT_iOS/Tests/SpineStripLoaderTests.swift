//
//  SpineStripLoaderTests.swift
//  ReCIT_iOSTests
//
//  Unit tests for the pure parts of the spine-strip builder: crop geometry, the quarter
//  turn used by books lying flat, and the luminance → title-colour decision.
//  Network-free. See PRD 0002.
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

    // MARK: - Quarter turn (books lying flat)

    @Test func quarterTurnSwapsWidthAndHeight() throws {
        let strip: CGImage = try #require(Self.opaqueImage(width: 10, height: 300))
        let turned: CGImage = try #require(SpineStripLoader.turnedQuarter(strip))
        #expect(turned.width == 300)
        #expect(turned.height == 10)
    }

    // MARK: - Helpers

    private static func opaqueImage(width: Int, height: Int) -> CGImage? {
        guard let context: CGContext = .init(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(gray: 0.5, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
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
