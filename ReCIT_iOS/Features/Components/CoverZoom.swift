//
//  CoverZoom.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/10/2026.
//

import CoreGraphics

/// How far a cover shown full screen is magnified, and where it has been dragged to.
///
/// A gesture in flight is applied on top of what the previous gestures left (`pinching(by:)`,
/// `panning(by:)`), and folded into it when the finger lifts (`endPinch(by:)`, `endPan(by:)`).
/// The scale never leaves `scaleRange`, and a cover back at its fitted size is centred again: an
/// offset only means something while the cover is larger than the screen.
struct CoverZoom: Equatable {
    static let scaleRange: ClosedRange<CGFloat> = 1...4
    /// The magnification a double tap jumps to from the fitted size.
    static let doubleTapScale: CGFloat = 2.5

    private(set) var scale: CGFloat = 1
    private(set) var offset: CGSize = .zero

    var isZoomed: Bool { scale > Self.scaleRange.lowerBound }

    func pinching(by magnification: CGFloat) -> CoverZoom {
        var zoom: CoverZoom = self
        zoom.scale = Self.clamped(scale * magnification)
        if zoom.isZoomed == false {
            zoom.offset = .zero
        }
        return zoom
    }

    mutating func endPinch(by magnification: CGFloat) {
        self = pinching(by: magnification)
    }

    func panning(by translation: CGSize) -> CoverZoom {
        guard isZoomed else { return self }
        var zoom: CoverZoom = self
        zoom.offset = .init(
            width: offset.width + translation.width,
            height: offset.height + translation.height
        )
        return zoom
    }

    mutating func endPan(by translation: CGSize) {
        self = panning(by: translation)
    }

    /// A double tap magnifies a fitted cover, and brings a magnified one back to fit.
    mutating func toggle() {
        self = isZoomed ? .init() : .init(scale: Self.doubleTapScale, offset: .zero)
    }

    private static func clamped(_ scale: CGFloat) -> CGFloat {
        min(max(scale, scaleRange.lowerBound), scaleRange.upperBound)
    }
}
