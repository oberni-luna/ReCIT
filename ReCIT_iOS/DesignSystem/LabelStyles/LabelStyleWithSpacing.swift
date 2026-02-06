//
//  LabelStyleWithSpacing.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/02/2026.
//
import SwiftUI

struct LabelStyleWithSpacing: LabelStyle {
    var spacing: DesignSystem.Spacing = .zero

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}
