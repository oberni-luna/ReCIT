//
//  EditAuthorFormView.swift
//  ReCIT_iOS
//
//  « Modifier l'auteur·ice » — everything inventaire.io accepts on a person, Figma `A1`
//  (`815:7335`): their name per language, pseudonyms, writing languages, dates of birth and
//  death; their movement and influences; their identifiers, links, and the namesakes they are
//  not to be confused with.
//
//  What changes here is the person's, for every work they are named on, and goes with this
//  screen's own « Enregistrer » (`EditEntityView`).
//

import SwiftUI

struct EditAuthorFormView: View {
    @Binding var edit: EntityEdit
    /// Pushes the screen that changes one property: an entity's values, a date.
    let onOpenProperty: (EditionProperty) -> Void
    /// Pushes the list of catalogues an identifier — or a link — is added to.
    let onAddIdentifier: (EditionProperty.Group) -> Void

    var body: some View {
        Section {
            EntityLabelRows(
                edit: $edit,
                fieldName: { String(localized: "edit_author.name_field \($0)") },
                addTitle: "edit_author.add_name"
            )
            EditionTextValuesRows(property: .pseudonym, properties: $edit.properties, addPlaceholder: "edit_author.add_pseudonym")
            EditionEntityPropertyButton(property: .writingLanguages, properties: edit.properties, placeholder: "edition_property.language.placeholder", onOpen: onOpenProperty)
            EditionDateButton(property: .birthDate, properties: edit.properties, onOpen: onOpenProperty)
            EditionDateButton(property: .deathDate, properties: edit.properties, onOpen: onOpenProperty)
        } header: {
            CreateBookSectionHeader("edit_author.header")
        } footer: {
            CreateBookSectionFooter("edit_author.general.footer")
        }

        EditEntityPropertiesSection(
            properties: [.movement, .influencedBy],
            values: edit.properties,
            header: "edit_author.influences.header",
            footer: "edit_author.influences.footer",
            onOpen: onOpenProperty
        )

        EditionIdentifiersSection(group: .databases, properties: $edit.properties, footer: "edit_author.databases.footer") {
            onAddIdentifier(.databases)
        }

        EditionIdentifiersSection(group: .links, properties: $edit.properties, footer: "edit_author.links.footer") {
            onAddIdentifier(.links)
        }

        EditEntityPropertiesSection(
            properties: [.humanDifferentFrom],
            values: edit.properties,
            header: "edit_entity.misc.header",
            footer: "edit_author.misc.footer",
            onOpen: onOpenProperty
        )
    }
}
