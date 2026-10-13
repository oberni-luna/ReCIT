//
//  SupportAmountPicker.swift
//  ReCIT_iOS
//
//  « Choisir un montant »: the three amounts side by side, as equal tiles, the chosen one filled
//  night green. A price the App Store has not given yet reads « — », and its tile cannot be
//  chosen.
//

import SwiftUI

struct SupportAmountPicker: View {
    @Binding var selection: DonationTier
    /// What each tier costs, as the sheet writes it; nil while unknown.
    let price: (DonationTier) -> String?

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            Text("support.amounts")
                .textStyle(.caption200)
                .foregroundStyle(.foregroundSecondary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: .small) {
                ForEach(DonationTier.allCases, id: \.self) { tier in
                    SupportAmountTile(
                        price: price(tier),
                        caption: tier.caption,
                        isSelected: tier == selection
                    ) {
                        selection = tier
                    }
                }
            }
        }
    }
}
