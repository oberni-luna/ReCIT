//
//  AboutInventaireValueRow.swift
//  ReCIT_iOS
//
//  One of the four things the À propos screen says about inventaire.io: a glyph in a pale green
//  disc, a bold line, and the sentence that explains it. The disc is what lets the rows hold on
//  a white screen, where a bare glyph beside a paragraph read as a bullet.
//

import SwiftUI

struct AboutInventaireValueRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    /// The disc's side — the Figma pass's 40 pt.
    private let badgeSide: CGFloat = 40

    var body: some View {
        HStack(alignment: .top, spacing: .sMedium) {
            Image(systemName: systemImage)
                .foregroundStyle(.foregroundTinted)
                .frame(width: badgeSide, height: badgeSide)
                .background(DesignSystem.Color.backgroundTinted.color, in: .circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: .xxSmall) {
                Text(title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)
                Text(detail)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AboutInventaireValueRow(
        systemImage: "book",
        title: "about.value.commons.title",
        detail: "about.value.commons.body"
    )
    .padding()
}
