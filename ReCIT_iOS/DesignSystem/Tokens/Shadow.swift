//
//  Shadow.swift
//  ReCIT_iOS
//
//  Named drop shadows, so two views that are meant to lift off the page by the same
//  amount cannot drift apart as one of them is tuned. Seeded with the single value the
//  focus cell's cover art and the shelf label share; the other documented shadows stay
//  literals for now and have an obvious home to move into. See PRD 0003.
//

import SwiftUI

public extension DesignSystem {

    enum Shadow: Sendable {
        /// Paper lifted a millimetre off the surface: black 18%, blur 3, offset (0, 2).
        case light

        public var color: SwiftUI.Color {
            switch self {
            case .light: .black.opacity(0.18)
            }
        }

        public var radius: CGFloat {
            switch self {
            case .light: 3
            }
        }

        public var offset: CGSize {
            switch self {
            case .light: .init(width: 0, height: 2)
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
