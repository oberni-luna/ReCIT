//
//  EditionIdentifiersSection.swift
//  ReCIT_iOS
//
//  « Bases bibliographiques » and « Autres données » in « Modifier l'édition »: the identifiers
//  of the edition in library catalogues, and its links. Each value is a row, taken away with a
//  swipe; the last row adds one, through the list of catalogues — or of links — and a field
//  checked against the server's pattern. Empty, the section is reduced to that row.
//

import SwiftUI

struct EditionIdentifiersSection: View {
    let group: EditionProperty.Group
    @Binding var properties: EditionProperties
    let onAdd: () -> Void

    private var entries: [EditionIdentifierEntry] {
        EditionProperty.properties(in: group).flatMap { property in
            properties.values(of: property).compactMap(\.claim).map { EditionIdentifierEntry(property: property, value: $0) }
        }
    }

    var body: some View {
        Section {
            ForEach(entries) { entry in
                EditionPropertyRow(
                    label: entry.property.label,
                    value: entry.value.text,
                    placeholder: "",
                    trailing: .none
                )
                .swipeActions(edge: .trailing) {
                    Button("edit_edition.remove", role: .destructive) {
                        remove(entry.value, from: entry.property)
                    }
                }
            }

            EditEditionActionRow(
                title: group == .databases ? "edit_edition.databases.add" : "edit_edition.links.add",
                action: onAdd
            )
            .accessibilityIdentifier(group == .databases ? "e2e.editEdition.addIdentifier" : "e2e.editEdition.addLink")
        } header: {
            CreateBookSectionHeader(group == .databases ? "edit_edition.databases.header" : "edit_edition.links.header")
        } footer: {
            CreateBookSectionFooter(group == .databases ? "edit_edition.databases.footer" : "edit_edition.links.footer")
        }
    }

    private func remove(_ value: ClaimLiteral, from property: EditionProperty) {
        guard let index = properties.values(of: property).firstIndex(where: { $0.claim == value }) else { return }
        properties.remove(atOffsets: [index], from: property)
    }
}

/// One identifier or link of the edition, as a row.
private struct EditionIdentifierEntry: Identifiable {
    let property: EditionProperty
    let value: ClaimLiteral

    var id: String { "\(property.uri) \(value.text)" }
}
