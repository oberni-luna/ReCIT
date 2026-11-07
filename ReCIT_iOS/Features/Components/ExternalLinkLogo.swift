//
//  ExternalLinkLogo.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import SwiftUI

/// A site's logo, as an external link shows it: a rounded square with a hairline inside its edge,
/// so a white logo still has one on a white cell. Figma `Brand / Logo`.
struct ExternalLinkLogo: View {
    private static let side: CGFloat = 28
    private static let cornerRadius: CGFloat = 6

    private let logo: ImageResource

    init(_ logo: ImageResource) {
        self.logo = logo
    }

    var body: some View {
        Image(logo)
            .resizable()
            .scaledToFill()
            .frame(width: Self.side, height: Self.side)
            .clipShape(.rect(cornerRadius: Self.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .strokeBorder(DesignSystem.Color.borderDefault.color, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: .medium) {
        ExternalLinkLogo(.bookshopRecyclivre)
        ExternalLinkLogo(.bookshopChezMonLibraire)
    }
    .padding()
}
