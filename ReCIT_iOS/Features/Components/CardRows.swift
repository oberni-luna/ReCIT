//
//  CardRows.swift
//  ReCIT_iOS
//
//  Rows on one rounded card, a hairline between two of them: what an inset grouped `List`
//  section draws, for a screen that is a `ScrollView` — the only container that pins a header
//  while its content scrolls (a reader's profile, PRD 0031). The card is the forms' and the book
//  screen's, `backgroundFormCell` on `backgroundForm`.
//

import SwiftUI

struct CardRows<Data: RandomAccessCollection, Row: View>: View where Data.Element: Identifiable {
    let data: Data
    @ViewBuilder let row: (Data.Element) -> Row

    var body: some View {
        LazyVStack(spacing: .zero) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, element in
                if index > 0 {
                    Divider()
                        .padding(.leading, .medium)
                }

                row(element)
                    .padding(.vertical, .sMedium)
                    .padding(.horizontal, .medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(DesignSystem.Color.backgroundFormCell.color)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium.rawValue))
        .padding(.horizontal, .medium)
    }
}
