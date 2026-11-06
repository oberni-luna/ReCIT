//
//  Shadow.swift
//  ReCIT_iOS
//
//  Named drop shadows, so two views that are meant to lift off the page by the same
//  amount cannot drift apart as one of them is tuned. One case per Figma shadow style
//  the code uses; feature code never writes a shadow literal. See PRD 0003.
//

import SwiftUI

public extension DesignSystem {

    enum Shadow: Sendable {
        /// Paper lifted a millimetre off the surface: black 18%, blur 3, offset (0, 2).
        case light
        /// A painted cover resting on its shelf: black 16%, blur 1.5, offset (0, 1.5).
        case paintedBook
        /// Contact shade under the title on a spine: black 45%, blur 1, offset (0, 0.5).
        case bookSpine
        /// A shelf cover, standing or lying, lit from the left: black 22%, blur 3, offset (1, 2).
        case lyingBook
        /// A soft halo around the book screen's cover: black 10%, blur 10, no offset.
        case entityGlow

        public var color: SwiftUI.Color {
            switch self {
            case .light: .black.opacity(0.18)
            case .paintedBook: .black.opacity(0.16)
            case .bookSpine: .black.opacity(0.45)
            case .lyingBook: .black.opacity(0.22)
            case .entityGlow: .black.opacity(0.1)
            }
        }

        public var radius: CGFloat {
            switch self {
            case .light: 3
            case .paintedBook: 1.5
            case .bookSpine: 1
            case .lyingBook: 3
            case .entityGlow: 10
            }
        }

        public var offset: CGSize {
            switch self {
            case .light: .init(width: 0, height: 2)
            case .paintedBook: .init(width: 0, height: 1.5)
            case .bookSpine: .init(width: 0, height: 0.5)
            case .lyingBook: .init(width: 1, height: 2)
            case .entityGlow: .zero
            }
        }
    }
}

// MARK: Usage extensions
public extension View {
    func shadow(_ shadow: DesignSystem.Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.offset.width,
            y: shadow.offset.height
        )
    }
}
