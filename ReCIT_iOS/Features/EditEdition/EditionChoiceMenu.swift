//
//  EditionChoiceMenu.swift
//  ReCIT_iOS
//
//  A property whose value is one of a fixed few, set from a menu on its row: a work's type. The
//  same shape as an edition's format.
//

import SwiftUI

struct EditionChoiceMenu: View {
    let property: EditionProperty
    @Binding var properties: EditionProperties
    let placeholder: LocalizedStringKey

    private var selected: String? {
        properties.literal(of: property)?.string
    }

    var body: some View {
        Menu {
            Picker(
                selection: Binding<String?>(
                    get: { selected },
                    set: { properties.setLiteral($0.map(ClaimLiteral.string), for: property) }
                )
            ) {
                ForEach(property.choices) { choice in
                    Text(LocalizedStringKey(choice.label)).tag(Optional(choice.uri))
                }
                Text("edition_choice.none").tag(String?.none)
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            EditionPropertyRow(
                label: property.label,
                value: property.choiceName(of: selected),
                placeholder: placeholder,
                trailing: .menu
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.editEntity.\(property.uri)")
    }
}
