//
//  PrimaryButton.swift
// Trompet
//
//  Created by Olivier Berni on 12/11/2024.
//

import SwiftUI

struct LargeButtonStyle: ButtonStyle {
    public enum Style {
        /// Default
        case primary
        case secondary
        case destructive
    }

    init(_ style: Style = .primary) {
        self.style = style
    }

    @Environment(\.isEnabled) private var isEnabled

    private let style: Style

    private var verticalPadding: DesignSystem.Spacing {
        switch style {
        default:
            .medium
        }
    }

    private var horizontalPadding: DesignSystem.Spacing {
        switch style {
        default:
            .large
        }
    }

    private var textStyle: DesignSystem.TextStyle {
        switch style {
        default:
            .action300
        }
    }

    private var background: DesignSystem.Color {
        switch style {
        case .primary:
            .backgroundTintedInverse
        case .secondary:
            .clear
        case .destructive:
            .backgroundError
        }
    }

    private var foreground: DesignSystem.Color {
        switch style {
        case .primary:
            .foregroundTintedInverse
        case .secondary:
            .foregroundTinted
        case .destructive:
            .foregroundError
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(isEnabled ? self.background : .backgroundDisable)
            .foregroundStyle(isEnabled ? self.foreground : .foregroundDisable)
            .textStyle(textStyle)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)

    }
}

extension ButtonStyle where Self == LargeButtonStyle {
    static func primary() -> Self {
        .init()
    }

    static func secondary() -> Self {
        .init(.secondary)
    }

    static func destructive() -> Self {
        .init(.destructive)
    }
}
