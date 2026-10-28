//
//  EditionChoiceButton.swift
//  ReCIT_iOS
//
//  A row whose value is one of a fixed list too long for a menu — a work's form — and which
//  pushes that list.
//

import SwiftUI

struct EditionChoiceButton: View {
    let property: EditionProperty
    let properties: EditionProperties
    let placeholder: LocalizedStringKey
    let onOpen: (EditionProperty) -> Void

    var body: some View {
        Button {
            onOpen(property)
        } label: {
            EditionPropertyRow(
                label: property.label,
                value: property.choiceName(of: properties.literal(of: property)?.string),
                placeholder: placeholder
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.editEntity.\(property.uri)")
    }
}
