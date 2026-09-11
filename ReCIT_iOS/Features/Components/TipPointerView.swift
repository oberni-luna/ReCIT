//
//  TipPointerView.swift
//  ReCIT_iOS
//
//  The astuce card's pointer: a 20 × 9 triangle, in the card's own green, aimed downwards at
//  whatever the screen wants pointed at.
//
//  **It lives outside the card on purpose** (PRD 0013). In Figma that is a constraint — an
//  instance node cannot be moved, so the triangle is drawn in the screen beside the card
//  instance — and it happens to be the right structure here too: the card carries copy and
//  nothing else, and the screen is the only thing that knows where the first book of a
//  carousel, or a button in a bar, actually sits.
//
//  The 20 × 9 is the mockup's own measurement of this shape, so it is stated here rather
//  than passed in: it is the pointer's size, not a spacing, and no caller has a reason to
//  disagree with it.
//

import SwiftUI

struct TipPointerView: View {

    /// The mockup's pointer, to the pixel (the SORT-* frames of `Astuces · TipKit`).
    static let size: CGSize = .init(width: 20, height: 9)

    var body: some View {
        TipPointerShape()
            .fill(DesignSystem.Color.backgroundTintedInverse.color)
            .frame(width: Self.size.width, height: Self.size.height)
            // Decoration: the card above it already says everything there is to say, and a
            // shape VoiceOver stopped on would be an element with nothing in it.
            .accessibilityHidden(true)
    }
}
