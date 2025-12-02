//
//  IconButtonStyle.swift
// Trompet
//
//  Created by Quentin Noblet on 07/11/2024.
//

import SwiftUI

public struct IconButtonStyle: ButtonStyle {
    public enum Style {
        /// Default
        case `default`
        case background
        case mini
        case miniMini
    }

    private let style: Style
    @Environment(\.isEnabled) private var isEnabled

    private var foregroundColor: DesignSystem.Color {
        isEnabled ? .surfaceTintPrimary : .textDisable
    }

    private var backgroundColor: DesignSystem.Color {
        switch style {
        case .default, .miniMini:
                .clear
        case .background:
                .surfaceTintSecondary
        case .mini:
                .surfaceElevated
        }
    }

    private var iconSize: CGFloat {
        switch style {
        case .default, .background:
            24
        case .mini:
            16
        case .miniMini:
            8
        }
    }

    private var cornerRadius: DesignSystem.CornerRadius {
        switch style {
        case .default, .miniMini:
            return .none
        case .background:
            return .medium
        case .mini:
            return .rounded
        }
    }

    public init(_ style: Style = .default) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .defaultPressedEffect(isPressed: configuration.isPressed)
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(isEnabled ? foregroundColor : .textDisable)
            .padding(.all, .small)
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: cornerRadius.rawValue))
    }
}
