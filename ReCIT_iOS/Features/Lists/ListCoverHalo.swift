//
//  ListCoverHalo.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import SwiftUI

/// The ring around the cover a list arrives on from a book screen: a tinted line close to the
/// cover's edge, a faint wide one further out, both fading to nothing as soon as they appear.
/// It follows the cover's corners, a disc for an author.
struct ListCoverHalo: View {
    static let fadeDuration: TimeInterval = 1.2

    // Figma `944:8280`: neither offset is a spacing token.
    private static let ringOffset: CGFloat = 5
    private static let ringWidth: CGFloat = 2
    private static let glowOffset: CGFloat = 11
    private static let glowWidth: CGFloat = 8
    private static let glowOpacity: Double = 0.14

    let cornerRadius: CGFloat

    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            outline(offset: Self.glowOffset, width: Self.glowWidth)
                .opacity(Self.glowOpacity)

            outline(offset: Self.ringOffset, width: Self.ringWidth)
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: Self.fadeDuration)) {
                opacity = 0
            }
        }
    }

    private func outline(
        offset: CGFloat,
        width: CGFloat
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius + offset)
            .stroke(DesignSystem.Color.foregroundTinted.color, lineWidth: width)
            .padding(-offset)
    }
}

#Preview("Cover") {
    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.minimal.rawValue)
        .fill(DesignSystem.Color.backgroundDisable.color)
        .frame(width: 172, height: 258)
        .overlay {
            ListCoverHalo(cornerRadius: DesignSystem.CornerRadius.minimal.rawValue)
        }
}

#Preview("Portrait") {
    Circle()
        .fill(DesignSystem.Color.backgroundDisable.color)
        .frame(width: 200, height: 200)
        .overlay {
            ListCoverHalo(cornerRadius: 100)
        }
}
