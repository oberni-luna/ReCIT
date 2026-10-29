//
//  ListDetailRowButton.swift
//  ReCIT_iOS
//
//  A full-width row of a card that does one thing — « Voir la fiche du livre », « Retirer de la
//  liste ». `Row / Link` in the Figma file, drawn outside a `List` because the list's screen is a
//  scroll view around its cover flow.
//

import SwiftUI

struct ListDetailRowButton: View {
    let label: LocalizedStringKey
    let color: DesignSystem.Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .textStyle(.action300)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .medium)
                .padding(.vertical, .sMedium)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
