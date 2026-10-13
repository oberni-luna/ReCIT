//
//  SupportSplitCard.swift
//  ReCIT_iOS
//
//  Where a donation goes, in two equal halves side by side: Ex-libris on the left, inventaire.io
//  on the right, each with its face, its share and what it pays for. Equal on purpose — neither
//  half is tinted, since 50 / 50 drawn with one side highlighted reads as anything but.
//

import SwiftUI

struct SupportSplitCard: View {
    /// Each half's logo.
    private let logoSide: CGFloat = 32

    var body: some View {
        HStack(spacing: .zero) {
            SupportSplitHalf(name: "Ex-libris", detail: "support.split.app") {
                AppIconTile(size: logoSide)
            }
            Rectangle()
                .fill(DesignSystem.Color.borderDefault.color)
                .frame(width: 1)
            SupportSplitHalf(name: "inventaire.io", detail: "support.split.inventaire") {
                Image(.inventaireIo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSide, height: logoSide)
                    .clipShape(.rect(cornerRadius: .medium))
            }
        }
        // Both halves as tall as the taller one, so the divider runs the card's full height.
        .fixedSize(horizontal: false, vertical: true)
        .overlay {
            RoundedRectangle(cornerRadius: .rounded)
                .strokeBorder(DesignSystem.Color.borderDefault.color, lineWidth: 1)
        }
    }
}

#Preview {
    SupportSplitCard()
        .padding()
}
