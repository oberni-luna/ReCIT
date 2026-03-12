//
//  TagLabelStyle.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import SwiftUI

/// A label style that renders an icon and title as a tinted pill tag.
struct TagLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 16

    enum Color {
        case tinted
        case secondary
    }

    let color: Color

    var background: DesignSystem.Color {
        switch color {
        case .tinted:
            .backgroundTinted
        case .secondary:
            .backgroundSecondary
        }
    }
    var foreground: DesignSystem.Color {
        switch color {
        case .tinted:
            .foregroundTinted
        case .secondary:
            .foregroundSecondary
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .xSmall) {
            configuration.icon
                .frame(width: iconSize, height: iconSize)
            configuration.title
        }
        .textStyle(.action200)
        .foregroundStyle(foreground)
        .padding(.horizontal, .small)
        .padding(.vertical, .xSmall)
        .background(background)
        .clipShape(.rect(cornerRadius: .minimal))
    }
}

extension LabelStyle where Self == TagLabelStyle {
    static var tag: TagLabelStyle { .init(color: .tinted) }
    static var secondaryTag: TagLabelStyle { .init(color: .secondary) }
}
