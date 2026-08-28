//
//  WelcomeValueRow.swift
//  ReCIT_iOS
//
//  One of the welcome screen's three uses: a glyph, a title, and a sentence.
//
//  The glyph is sized with `@ScaledMetric` rather than pinned at 24pt, on the precedent of
//  `TagLabelStyle`. A row whose text grows to an accessibility size beside a glyph that does not
//  reads as a bullet point that fell off, and this screen is one of the two the whole feature is
//  judged on at those sizes.
//
//  Top-aligned, not centred: at two lines of body text a centred glyph floats in the middle of
//  the paragraph instead of marking its start.
//
//  See PRD 0010 and issue 0056.
//

import SwiftUI

struct WelcomeValueRow: View {
    let glyph: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    /// The design's 24pt, following Dynamic Type so it stays the size of the text beside it.
    @ScaledMetric(relativeTo: .body) private var glyphSize: CGFloat = 24

    var body: some View {
        HStack(alignment: .top, spacing: .medium) {
            Image(systemName: glyph)
                .resizable()
                .scaledToFit()
                .frame(width: glyphSize, height: glyphSize)
                .foregroundStyle(.foregroundTinted)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text(title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)

                Text(message)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    VStack(spacing: .large) {
        WelcomeValueRow(
            glyph: "book",
            title: "welcome.value.inventory.title",
            message: "welcome.value.inventory.body"
        )
        WelcomeValueRow(
            glyph: "arrow.left.arrow.right",
            title: "welcome.value.lend.title",
            message: "welcome.value.lend.body"
        )
        WelcomeValueRow(
            glyph: "person",
            title: "welcome.value.borrow.title",
            message: "welcome.value.borrow.body"
        )
    }
    .padding(.all, .medium)
}
