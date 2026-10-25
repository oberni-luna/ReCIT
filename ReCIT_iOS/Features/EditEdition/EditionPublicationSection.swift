//
//  EditionPublicationSection.swift
//  ReCIT_iOS
//
//  « Publication » in « Modifier l'édition »: the publisher, the collection, the date and the
//  language. Each row pushes its own screen — a search for an entity, or the date's precision —
//  which the flow decides, since the screens belong to its navigation stack.
//

import SwiftUI

struct EditionPublicationSection: View {
    let properties: EditionProperties
    /// Pushes the screen that changes `property`.
    let onOpen: (EditionProperty) -> Void

    var body: some View {
        Section {
            EditionEntityPropertyButton(property: .publisher, properties: properties, placeholder: "edition_property.publisher.placeholder", onOpen: onOpen)
            EditionEntityPropertyButton(property: .collection, properties: properties, placeholder: "edition_property.collection.placeholder", onOpen: onOpen)

            Button {
                onOpen(.publicationDate)
            } label: {
                EditionPropertyRow(
                    label: EditionProperty.publicationDate.label,
                    value: properties.literal(of: .publicationDate)?.string.flatMap(PublicationDate.init)?.displayed,
                    placeholder: "edition_property.publication_date.placeholder"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e.editEdition.publicationDate")

            EditionEntityPropertyButton(property: .language, properties: properties, placeholder: "edition_property.language.placeholder", onOpen: onOpen)
        } header: {
            CreateBookSectionHeader("edit_edition.publication.header")
        } footer: {
            CreateBookSectionFooter("edit_edition.publication.footer")
        }
    }
}
