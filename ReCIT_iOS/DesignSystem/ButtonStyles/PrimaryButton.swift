//
//  PrimaryButton.swift
// Trompet
//
//  Created by Olivier Berni on 12/11/2024.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    public enum Style {
        /// Default
        case `default`
        case small
    }

    init(_ style: Style = .default) {
        self.style = style
    }

    private let style: Style
    @Environment(\.isEnabled) private var isEnabled

    private var iconSize: CGFloat {
        switch style {
        case .default:
            20
        case .small:
            16
        }
    }

    private var verticalPadding: DesignSystem.Spacing {
        switch style {
        case .default:
            .medium
        case .small:
            .small
        }
    }

    private var horizontalPadding: DesignSystem.Spacing {
        switch style {
        case .default:
            .large
        case .small:
            .medium
        }
    }

    private var textStyle: DesignSystem.TextStyle {
        switch style {
        case .default:
                .content300Bold
        case .small:
                .content200Bold
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .defaultPressedEffect(isPressed: configuration.isPressed)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(isEnabled ? .surfaceTintPrimary : .surfaceDisable)
            .foregroundStyle(.textOnTint)
            .cornerRadius(.medium)
            .textStyle(textStyle)
    }
}
