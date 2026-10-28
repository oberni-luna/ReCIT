//
//  EditionDateButton.swift
//  ReCIT_iOS
//
//  A row whose value is a date — a work's first publication, a person's birth or death — and
//  which pushes the date's screen.
//

import SwiftUI

struct EditionDateButton: View {
    let property: EditionProperty
    let properties: EditionProperties
    let onOpen: (EditionProperty) -> Void

    var body: some View {
        Button {
            onOpen(property)
        } label: {
            EditionPropertyRow(
                label: property.label,
                value: properties.literal(of: property)?.string.flatMap(PublicationDate.init)?.displayed,
                placeholder: "edition_property.publication_date.placeholder"
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.editEntity.\(property.uri)")
    }
}
