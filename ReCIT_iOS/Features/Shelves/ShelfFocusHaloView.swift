//
//  ShelfFocusHaloView.swift
//  ReCIT_iOS
//
//  The blur that marks a shelf as focused: a material — which blurs whatever is behind it —
//  spilling well past the card and fading out radially, so it has no edge. It is drawn
//  between the shelf's background and its plank, so the paper and the neighbouring étagères
//  go soft while the books and the plank stay sharp.
//
//  The carousel's scroll view clips it, so the blur stops at the carousel row: the page's
//  heading and the book list below stay sharp. That costs nothing in practice, because the
//  strip immediately above and below a card is empty paper, where a blur shows nothing.
//  See ADR 0006.
//

import SwiftUI

struct ShelfFocusHaloView: View {
    /// How far the blur reaches from the card's centre.
    let radius: CGFloat

    /// How much of that reach stays fully blurred before the fade begins. Set so the card's
    /// own corners are still inside the solid part.
    private let solidFraction: CGFloat = 0.7

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .frame(width: radius * 2, height: radius * 2)
            .mask {
                RadialGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: solidFraction),
                        .init(color: .clear, location: 1)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            }
            .allowsHitTesting(false)
    }
}
