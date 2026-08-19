//
//  ScanOverlayPalette.swift
//  ReCIT_iOS
//
//  Colours for the scanner's result row. Deliberately mode-independent, pinned to the
//  design system's *dark* values — which is how every colour in the Figma capture resolved,
//  and not by accident: the row floats on a live camera feed, which is dark and
//  unpredictable whatever the user's appearance setting is. Same reasoning as
//  `ShelfPalette`'s label paper (PRD 0003), in the opposite direction: that one sits on a
//  permanently light illustration, this one on a permanently unpredictable image.
//
//  The scrim is chosen, not transcribed: the design's `Overlay Bottom-Top` variable came
//  back empty from the capture. Stops are picked so the row's ink clears WCAG contrast over
//  a white camera image — point the phone at a pale book on a pale table and the title still
//  reads — while the feed stays visible enough that the scanner does not feel occluded.
//
//  See PRD 0005.
//

import SwiftUI

enum ScanOverlayPalette {
    /// `foreground/default`, dark value (#F1F1F1) — the title and the authors.
    static let ink: Color = .init("color/gray/50")

    /// `foreground/tinted`, dark value (#E7FFCE) — the action's glyph and the confirmation.
    static let tint: Color = .init("color/green/200")

    /// `background/tinted`, dark value (#344E41) — the action's disc.
    static let tintedSurface: Color = .init("color/green/900")

    /// The hole a cover sits in before its image arrives: a darker patch of the scrim rather
    /// than a design-system surface, which would be a pale card in light appearance.
    static let coverBacking: Color = .black.opacity(0.35)

    /// Bottom-up veil the row sits on. Opaque enough at the bottom edge to carry light text
    /// over any image, fading out well above the row so it reads as a gradient rather than
    /// as a panel with a hard top edge.
    static let scrim: LinearGradient = .init(
        stops: [
            .init(color: .black.opacity(0.88), location: 0),
            .init(color: .black.opacity(0.64), location: 0.4),
            .init(color: .black.opacity(0.24), location: 0.75),
            .init(color: .black.opacity(0), location: 1)
        ],
        startPoint: .bottom,
        endPoint: .top
    )
}
