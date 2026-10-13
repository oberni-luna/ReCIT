//
//  SupportExLibrisCard.swift
//  ReCIT_iOS
//
//  The card at the top of the Profil that asks for a coffee: night green, the app's own
//  illustration spilling off its right edge, the half that goes to inventaire.io said before
//  anything is asked, and « Faire un don », which opens the donation sheet.
//
//  It can be put away by the cross in its corner, for good on this device, and it goes on its
//  own once a donation has gone through — `ProfileView` decides, from both.
//
//  The text keeps clear of the illustration by a fixed trailing reserve rather than by measuring
//  it: the picture is decoration, and at large text sizes the card simply grows taller under it.
//
//  See the Figma frame `Carte C · Vert nuit` (`534:16830`), as placed in `P1` (`588:17842`).
//

import SwiftUI

struct SupportExLibrisCard: View {
    let onDonate: () -> Void
    let onDismiss: () -> Void

    /// The illustration's side, and how far it hangs past the card's right and bottom edges.
    private let artSide: CGFloat = 190
    private let artOverhang: CGSize = .init(width: 40, height: 15)
    /// What the text leaves to the illustration on its right.
    private let artReserve: CGFloat = 128
    /// The inventaire.io logo in the chip.
    private let logoSide: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            Text("support.card.title")
                .textStyle(.content400Bold)
                .accessibilityAddTraits(.isHeader)
            Text("support.card.body")
                .textStyle(.content300)
            share
            Button("support.card.donate", action: onDonate)
                .buttonStyle(.pill(.tinted))
                .padding(.top, .xSmall)
                .accessibilityIdentifier("e2e.profile.support.donate")
        }
        .foregroundStyle(.foregroundInverse)
        .padding(.vertical, .medium)
        .padding(.leading, .medium)
        .padding(.trailing, artReserve)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottomTrailing) {
            Image(.booksOnShelf)
                .resizable()
                .scaledToFit()
                .frame(width: artSide, height: artSide)
                .offset(x: artOverhang.width, y: artOverhang.height)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .topTrailing) {
            Button("support.card.dismiss", systemImage: "xmark.circle", action: onDismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.foregroundInverse)
                .padding(.all, .small)
                .accessibilityIdentifier("e2e.profile.support.dismiss")
        }
        .background(.backgroundTintedInverse)
        .clipShape(.rect(cornerRadius: .roundedLarge))
        .shadow(.light)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("e2e.profile.support")
    }

    /// « 50 % pour inventaire.io », with its logo, on a veil of the card's own ink.
    private var share: some View {
        HStack(spacing: .xSmall) {
            Image(.inventaireIo)
                .resizable()
                .scaledToFit()
                .frame(width: logoSide, height: logoSide)
                .clipShape(.rect(cornerRadius: .minimal))
                .accessibilityHidden(true)
            Text("support.card.share")
                .textStyle(.caption200)
        }
        .padding(.vertical, .xSmall)
        .padding(.leading, .xSmall)
        .padding(.trailing, .small)
        .background(DesignSystem.Color.foregroundInverse.color.opacity(0.14), in: .capsule)
    }
}

#Preview {
    SupportExLibrisCard(onDonate: {}, onDismiss: {})
        .padding()
}
