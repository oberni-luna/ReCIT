//
//  SupportSplitHalf.swift
//  ReCIT_iOS
//
//  One half of the 50 / 50: a logo and the share beside it, the name under them, and what that
//  half pays for. The share is a formatted percentage, so it is written « 50 % » in French and
//  « 50% » in English without a string to translate.
//

import SwiftUI

struct SupportSplitHalf<Logo: View>: View {
    /// A name, not a phrase: « Ex-libris », « inventaire.io ». Never translated.
    let name: String
    let detail: LocalizedStringKey
    @ViewBuilder let logo: () -> Logo

    private let share: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            HStack(spacing: .small) {
                logo()
                    .accessibilityHidden(true)
                Text(share, format: .percent)
                    .textStyle(.title50)
                    .foregroundStyle(.foregroundTinted)
            }
            Text(verbatim: name)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)
            Text(detail)
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
        }
        .padding(.all, .medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }
}
