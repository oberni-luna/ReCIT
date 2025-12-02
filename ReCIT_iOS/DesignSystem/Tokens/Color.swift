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
        case textDefault
        case textSecondary
        case textTertiary
        case textDisable
        case textTintPrimary
        case textOnTint
        case textOnTintInverted
        case textTintSecondary
        case textError

        case surfaceDefault
        case surfaceDisable
        case surfaceSecondary
        case surfaceTertiary
        case surfaceElevated
        case surfaceTintPrimary
        case surfaceTintSecondary
        case surfaceGradientLeft
        case surfaceGradientRight
        case surfaceLight

        case borderDefault
        case borderTint
        case borderSecondary
        case borderTertiary
        case borderQuaternary
        case borderPrimary
        case borderError

        case shadowTint
        case shadow

        case clear

        public var color: SwiftUI.Color {
            switch self {
            case .textDefault: .init(.textDefault)
            case .textSecondary: .init(.textSecondary)
            case .textTertiary: .init(.textTertiary)
            case .textDisable: .init(.textDisable)
            case .textTintPrimary: .init(.textTintPrimary)
            case .textOnTint: .init(.textOnTint)
            case .textOnTintInverted: .init(.textOnTintInverted)
            case .textTintSecondary: .init(.textTintSecondary)
            case .textError: .init(.textError)

            case .surfaceDefault: .init(.surfaceDefault)
            case .surfaceDisable: .init(.surfaceDisable)
            case .surfaceSecondary: .init(.surfaceSecondary)
            case .surfaceTertiary: .init(.surfaceTertiary)
            case .surfaceElevated: .init(.surfaceElevated)
            case .surfaceTintPrimary: .init(.surfaceTintPrimary)
            case .surfaceTintSecondary: .init(.surfaceTintSecondary)
            case .surfaceGradientLeft: .init(.surfaceGradientLeft)
            case .surfaceGradientRight: .init(.surfaceGradientRight)
            case .surfaceLight: .init(.surfaceLight)

            case .borderDefault: .init(.borderDefault)
            case .borderTint: .init(.borderTint)
            case .borderSecondary: .init(.borderSecondary)
            case .borderPrimary: .init(.borderPrimary)
            case .borderTertiary: .init(.borderTertiary)
            case .borderQuaternary: .init(.borderQuaternary)
            case .borderError: .init(.borderError)

            case .shadowTint: .init(red: 0.25, green: 0.07, blue: 0.36).opacity(0.1)
            case .shadow: .init(red: 0.25, green: 0.07, blue: 0.36).opacity(0.3)

            case .clear: .clear
            }
        }

        public var uiColor: UIColor {
            switch self {
            case .textDefault: .init(.textDefault)
            case .textSecondary: .init(.textSecondary)
            case .textTertiary: .init(.textTertiary)
            case .textDisable: .init(.textDisable)
            case .textTintPrimary: .init(.textTintPrimary)
            case .textOnTint: .init(.textOnTint)
            case .textOnTintInverted: .init(.textOnTintInverted)
            case .textTintSecondary: .init(.textTintSecondary)
            case .textError: .init(.textError)

            case .surfaceDefault: .init(.surfaceDefault)
            case .surfaceDisable: .init(.surfaceDisable)
            case .surfaceSecondary: .init(.surfaceSecondary)
            case .surfaceTertiary: .init(.surfaceTertiary)
            case .surfaceElevated: .init(.surfaceElevated)
            case .surfaceTintPrimary: .init(.surfaceTintPrimary)
            case .surfaceTintSecondary: .init(.surfaceTintSecondary)
            case .surfaceGradientLeft: .init(.surfaceGradientLeft)
            case .surfaceGradientRight: .init(.surfaceGradientRight)
            case .surfaceLight: .init(.surfaceLight)

            case .borderDefault: .init(.borderDefault)
            case .borderTint: .init(.borderTint)
            case .borderSecondary: .init(.borderSecondary)
            case .borderPrimary: .init(.borderPrimary)
            case .borderTertiary: .init(.borderTertiary)
            case .borderError: .init(.borderError)
            case .borderQuaternary: .init(.borderQuaternary)

            case .shadowTint: .init(red: 0.25, green: 0.07, blue: 0.36, alpha: 0.1)
            case .shadow: .init(red: 0.25, green: 0.07, blue: 0.36, alpha: 0.3)

            case .clear: .clear
            }
        }
    }
}

extension View {
    @inlinable nonisolated public func foregroundStyle(_ style: DesignSystem.Color) -> some View {
        self.foregroundStyle(style.color)
    }

    @inlinable nonisolated public func background(_ style: DesignSystem.Color, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View {
        self.background(style.color, ignoresSafeAreaEdges: edges)
    }

    @inlinable nonisolated public func tint(_ tint: DesignSystem.Color) -> some View {
        self.tint(tint.color)
    }

    @inlinable nonisolated public func shadow(color: DesignSystem.Color = .shadowTint, radius: CGFloat = 6, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        self.shadow(color: color.color, radius: radius, x: x, y: y)
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
