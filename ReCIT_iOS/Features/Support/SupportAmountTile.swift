//
//  SupportAmountTile.swift
//  ReCIT_iOS
//
//  One amount: the price over what it buys. Chosen, it takes the primary button's couple —
//  `background/tinted-inverse` under `foreground/tinted-inverse` — so the tile and « Donner »
//  below it read as one decision. Otherwise a hairline, on white.
//

import SwiftUI

struct SupportAmountTile: View {
    let price: String?
    let caption: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: .xxSmall) {
                Text(price ?? "—")
                    .textStyle(.title50)
                    .foregroundStyle(isSelected ? .foregroundTintedInverse : .foregroundDefault)
                Text(caption)
                    .textStyle(.footnote200)
                    .foregroundStyle(isSelected ? .foregroundTintedInverse : .foregroundSecondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .sMedium)
            .padding(.horizontal, .xSmall)
            .background {
                RoundedRectangle(cornerRadius: .rounded)
                    .fill(isSelected ? DesignSystem.Color.backgroundTintedInverse.color : .clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: .rounded)
                    .strokeBorder(isSelected ? .clear : DesignSystem.Color.borderDefault.color, lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: .rounded))
        }
        .buttonStyle(.plain)
        .disabled(price == nil)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}
