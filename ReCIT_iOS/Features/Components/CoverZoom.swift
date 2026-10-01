//
//  CoverZoom.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/10/2026.
//

import CoreGraphics

/// How far a cover shown full screen is magnified, and where it has been dragged to.
///
/// A scale of 1 is the cover fitted to the screen. `fillScale` is the scale at which it fills the
/// screen instead — known only once the cover has been laid out, through `measure(fitted:in:)`.
///
/// A gesture in flight is applied on top of what the previous gestures left (`pinching(by:)`,
/// `panning(by:)`), and folded into it when the finger lifts (`endPinch(by:)`, `endPan(by:)`).
/// The scale never leaves `scaleRange`, and a cover back at its fitted size is centred again: an
/// offset only means something while the cover is larger than the screen.
struct CoverZoom: Equatable {
    /// How far a pinch may go past the fitted size, whatever the cover's proportions.
    static let maximumPinchScale: CGFloat = 4

    private(set) var scale: CGFloat = 1
    private(set) var offset: CGSize = .zero
    private(set) var fillScale: CGFloat = 1

    /// From fitted to whichever is larger: four times that, or filled — a cover much narrower than
    /// the screen must still be able to fill it.
    var scaleRange: ClosedRange<CGFloat> { 1...max(Self.maximumPinchScale, fillScale) }

    var isZoomed: Bool { scale > scaleRange.lowerBound }

    /// Records the cover's size once fitted to `container`, which gives the scale that fills it.
    /// A cover with the screen's own proportions fills it at its fitted size.
    mutating func measure(fitted: CGSize, in container: CGSize) {
        guard fitted.width > 0, fitted.height > 0 else { return }
        fillScale = max(
            1,
            container.width / fitted.width,
            container.height / fitted.height
        )
    }

    func pinching(by magnification: CGFloat) -> CoverZoom {
        var zoom: CoverZoom = self
        zoom.scale = clamped(scale * magnification)
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

    /// A double tap fills the screen with a fitted cover, and fits anything else back to it — a
    /// filled cover as well as one pinched or dragged anywhere in between.
    mutating func toggle() {
        scale = isZoomed ? scaleRange.lowerBound : fillScale
        offset = .zero
    }

    private func clamped(_ scale: CGFloat) -> CGFloat {
        min(max(scale, scaleRange.lowerBound), scaleRange.upperBound)
    }
}
