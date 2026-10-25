//
//  EditionEntityPropertyButton.swift
//  ReCIT_iOS
//
//  A property of the edition whose values are entities — a publisher, a collection, a language,
//  the people of a role — as one row: their names joined, or an invitation, and a chevron to the
//  screen that changes them.
//

import SwiftUI

/// A row whose values are entities: their names joined, or an invitation.
struct EditionEntityPropertyButton: View {
    let property: EditionProperty
    let properties: EditionProperties
    let placeholder: LocalizedStringKey
    let onOpen: (EditionProperty) -> Void

    var body: some View {
        let names: [String] = properties.entities(of: property).map(\.trimmedLabel)

        Button {
            onOpen(property)
        } label: {
            EditionPropertyRow(
                label: property.label,
                value: names.isEmpty ? nil : names.formatted(.list(type: .and)),
                placeholder: placeholder
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.editEdition.\(property.uri)")
    }
}
