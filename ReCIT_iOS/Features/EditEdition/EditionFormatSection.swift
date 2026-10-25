//
//  EditionFormatSection.swift
//  ReCIT_iOS
//
//  « Format » in « Modifier l'édition »: the format, chosen in a menu among the six inventaire.io
//  allows, and the numbers of pages and of volumes, typed. A count goes out as a number; an empty
//  field takes the claim away.
//

import SwiftUI

struct EditionFormatSection: View {
    @Binding var properties: EditionProperties

    var body: some View {
        Section {
            EditionFormatMenu(properties: $properties)
            EditionCountField(property: .numberOfPages, properties: $properties)
            EditionCountField(property: .numberOfVolumes, properties: $properties)
        } header: {
            CreateBookSectionHeader("edit_edition.format.header")
        } footer: {
            CreateBookSectionFooter("edit_edition.format.footer")
        }
    }
}

private struct EditionFormatMenu: View {
    @Binding var properties: EditionProperties

    private var format: EditionFormat? {
        properties.literal(of: .format)?.string.flatMap(EditionFormat.init(rawValue:))
    }

    var body: some View {
        Menu {
            Picker(
                selection: Binding<EditionFormat?>(
                    get: { format },
                    set: { properties.setLiteral($0.map { .string($0.rawValue) }, for: .format) }
                )
            ) {
                ForEach(EditionFormat.allCases) { format in
                    Text(format.name).tag(Optional(format))
                }
                Text("edition_format.none").tag(EditionFormat?.none)
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            EditionPropertyRow(
                label: EditionProperty.format.label,
                value: format.map { String(localized: $0.name) },
                placeholder: "edition_property.format.placeholder",
                trailing: .menu
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.editEdition.format")
    }
}

/// A positive count, typed. Anything but digits is dropped as it is typed.
private struct EditionCountField: View {
    let property: EditionProperty
    @Binding var properties: EditionProperties

    var body: some View {
        TextField(
            "edition_property.count.placeholder",
            text: Binding(
                get: { properties.literal(of: property)?.text ?? "" },
                set: { properties.setLiteral(property.literal(from: $0.filter(\.isNumber)), for: property) }
            )
        )
        .keyboardType(.numberPad)
        .textStyle(.content300)
        .foregroundStyle(.foregroundDefault)
        .withLabel(label: property.label)
        .accessibilityIdentifier("e2e.editEdition.\(property.uri)")
    }
}
