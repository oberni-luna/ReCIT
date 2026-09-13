//
//  PillButtonStyle.swift
//  ReCIT_iOS
//
//  `Action / Pill` (`358:357`) from the « Réseau » Figma pass: a button the size of a list row's
//  trailing control, where `LargeButtonStyle` — 55 pt tall, built to span a screen — would not
//  fit.
//
//  Same two colour couples as the large button, so nothing new enters the palette: `prominent`
//  is the primary's `background/tinted-inverse` over `foreground/tinted-inverse`, `tinted` is
//  the tag's `background/tinted` over `foreground/tinted`. Only the metrics differ, and the
//  pressed state is the same transformation as everywhere else.
//

import SwiftUI

struct PillButtonStyle: ButtonStyle {
    enum Style {
        /// The gesture being offered — « Accepter », « Ajouter ».
        case prominent
        /// The gesture beside it, weighed down a notch — « Refuser ».
        case tinted
    }

    init(_ style: Style = .tinted) {
        self.style = style
    }

    @Environment(\.isEnabled) private var isEnabled

    private let style: Style

    private var background: DesignSystem.Color {
        switch style {
        case .prominent:
            .backgroundTintedInverse
        case .tinted:
            .backgroundTinted
        }
    }

    private var foreground: DesignSystem.Color {
        switch style {
        case .prominent:
            .foregroundTintedInverse
        case .tinted:
            .foregroundTinted
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, .small)
            .padding(.horizontal, .medium)
            .background(isEnabled ? self.background : .backgroundDisable)
            .foregroundStyle(isEnabled ? self.foreground : .foregroundDisable)
            .tint(isEnabled ? self.foreground : .foregroundDisable)
            .textStyle(.action300)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static func pill(_ style: PillButtonStyle.Style = .tinted) -> Self {
        .init(style)
    }
}
