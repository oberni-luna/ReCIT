//
//  ActionButton.swift
// Trompet
//
//  Created by Quentin Noblet on 07/11/2024.
//

import Foundation
import SwiftUI

public struct ActionButtonStyle: ButtonStyle {
    public enum Style {
        /// Default
        case primary
        case secondary
        case destructive
    }

    private let style: Style
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var contentColor: DesignSystem.Color {
        guard isEnabled else { return .textDisable }
        switch style {
        case .primary, .secondary:
            return .textTintPrimary
        case .destructive:
            return .textError
        }
    }

    private var textStyle: DesignSystem.TextStyle {
        switch style {
        case .primary, .destructive:
            return .content300Bold
        case .secondary:
            return .content300
        }
    }

    init(_ style: Style) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .defaultPressedEffect(isPressed: configuration.isPressed)
            .textStyle(textStyle)
            .foregroundStyle(contentColor)
            .padding(.vertical, .xSmall)
    }
}
