//
//  Color.swift
// DansMaPoche
//
//  Created by Olivier Berni on 28/10/2024.
//

import Foundation
import SwiftUI

public extension DesignSystem {

    enum Color {

        case foregroundDefault
        case foregroundInverse
        case foregroundDisable
        case foregroundSecondary
        case foregroundTinted
        case foregroundTintedInverse
        case foregroundError
        case foregroundPlaceholder

        case backgroundDefault
        case backgroundInverse
        case backgroundDisable
        case backgroundSecondary
        case backgroundTinted
        case backgroundTintedInverse
        case backgroundError

        case borderDefault
        case borderTinted
        case borderError

        case clear

        public var color: SwiftUI.Color {
            switch self {
            case .clear: .clear
            case .foregroundDefault:
                .init(light:.init("color/gray/900"), dark:.init("color/gray/50"))
            case .foregroundInverse:
                .init(light:.init("color/gray/50"), dark:.init("color/gray/900"))
            case .foregroundDisable:
                .init(light:.init("color/gray/400"), dark:.init("color/gray/600"))
            case .foregroundSecondary:
                .init(light:.init("color/gray/600"), dark:.init("color/gray/400"))
            case .foregroundTinted, .borderTinted:
                .init(light:.init("color/green/700"), dark:.init("color/green/200"))
            case .foregroundTintedInverse:
                .init(light:.init("color/green/100"), dark:.init("color/green/900"))
            case .foregroundError, .borderError:
                .init(light:.init("color/red/800"), dark:.init("color/red/400"))
            case .foregroundPlaceholder:
                .init(light:.init("color/gray/400"), dark:.init("color/gray/600"))
            case .backgroundDefault:
                .init(light:.init("color/gray/0"), dark:.init("color/gray/1000"))
            case .backgroundInverse:
                    .init(light:.init("color/gray/900"), dark:.init("color/gray/200"))
            case .backgroundDisable:
                    .init(light:.init("color/gray/200"), dark:.init("color/gray/400"))
            case .backgroundSecondary:
                    .init(light:.init("color/gray/50"), dark:.init("color/gray/800"))
            case .backgroundTinted:
                    .init(light:.init("color/green/100"), dark:.init("color/green/900"))
            case .backgroundTintedInverse:
                    .init(light:.init("color/green/800"), dark:.init("color/green/200"))
            case .backgroundError:
                    .init(light:.init("color/red/100"), dark:.init("color/gray/700"))

            // The one token that is not a named asset. A border is a *veil over whatever is
            // behind it*, not a colour of its own: on white, on the sorting panel's
            // half-opaque wash, and on a shelf's watercolour it has to read as the same
            // hairline. A solid grey does that on exactly one backdrop — `gray/200` is
            // slightly green (it carries the brand tint into the greys) and on anything but
            // pure white it read as a drawn line rather than an edge.
            case .borderDefault:
                    .init(light: .black.opacity(0.1), dark: .white.opacity(0.1))
            }
        }

        public var uiColor: UIColor {
            switch self {
            case .clear: .clear
            default:
                UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                    ? UIColor(.black)
                    : UIColor(.white)
                }
            }
        }
    }
}

extension SwiftUI.Color {
    init(light: SwiftUI.Color, dark: SwiftUI.Color) {
        self = SwiftUI.Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

extension View {
    @inlinable public func foregroundStyle(_ style: DesignSystem.Color) -> some View {
        self.foregroundStyle(style.color)
    }

    @inlinable public func background(_ style: DesignSystem.Color, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View {
        self.background(style.color, ignoresSafeAreaEdges: edges)
    }

    @inlinable public func tint(_ tint: DesignSystem.Color) -> some View {
        self.tint(tint.color)
    }
}

extension DesignSystem.Color: CaseIterable {}

#Preview {
    Grid {
        ForEach(DesignSystem.Color.allCases, id: \.self) { color in
            Rectangle()
                .frame(width: 64, height: 64)
                .backgroundStyle(color.color)
        }
    }
}
