//
//  EditWorkFormView.swift
//  ReCIT_iOS
//
//  « Modifier l'œuvre » — everything inventaire.io accepts on a work, Figma `W1` (`815:6686`):
//  its title per language, type, form, original language and first publication; its authors and
//  everyone else who made it; its series, genres and subjects, its relations with other works,
//  its identifiers, links, and the works it is not to be confused with.
//
//  What changes here is the work's, for every edition of it, and goes with this screen's own
//  « Enregistrer » (`EditEntityView`).
//

import SwiftUI

struct EditWorkFormView: View {
    @Binding var edit: EntityEdit
    /// Pushes the screen that changes one property: an entity's values, a date, a list of choices.
    let onOpenProperty: (EditionProperty) -> Void
    /// Pushes the search for one more value of `property`.
    let onPick: (EditionProperty) -> Void
    /// Pushes the list of catalogues an identifier — or a link — is added to.
    let onAddIdentifier: (EditionProperty.Group) -> Void
    /// Pushes « Modifier l'auteur·ice » for the person with this uri.
    let onOpenEntity: (String) -> Void

    var body: some View {
        Section {
            EntityLabelRows(
                edit: $edit,
                fieldName: { String(localized: "edit_work.title_field \($0)") },
                addTitle: "edit_work.add_title"
            )
            EditionChoiceMenu(property: .workType, properties: $edit.properties, placeholder: "edit_work.type.placeholder")
            EditionChoiceButton(property: .workForm, properties: edit.properties, placeholder: "edit_work.form.placeholder", onOpen: onOpenProperty)
            EditionEntityPropertyButton(property: .originalLanguage, properties: edit.properties, placeholder: "edition_property.language.placeholder", onOpen: onOpenProperty)
            EditionDateButton(property: .firstPublicationDate, properties: edit.properties, onOpen: onOpenProperty)
        } header: {
            CreateBookSectionHeader("edit_work.header")
        } footer: {
            CreateBookSectionFooter("edit_work.general.footer")
        }

        Section {
            ForEach(edit.properties.entities(of: .author)) { author in
                EditEntityPersonRow(person: author, onOpen: onOpenEntity)
            }
            .onDelete { offsets in
                edit.properties.remove(atOffsets: offsets, from: .author)
            }

            EditEditionActionRow(
                title: edit.properties.entities(of: .author).isEmpty ? "edit_edition.work.add_author" : "edit_work.add_other_author",
                action: { onPick(.author) }
            )
            .accessibilityIdentifier("e2e.editWork.addAuthor")
        } header: {
            CreateBookSectionHeader("edit_work.authors.header")
        } footer: {
            CreateBookSectionFooter("edit_work.authors.footer")
        }

        EditEntityPropertiesSection(
            properties: EditionProperty.workRoles,
            values: edit.properties,
            header: "edit_work.roles.header",
            footer: "edit_work.roles.footer",
            onOpen: onOpenProperty
        )

        EditEntityPropertiesSection(
            properties: EditionProperty.comicRoles,
            values: edit.properties,
            header: "edit_work.comics.header",
            footer: "edit_work.comics.footer",
            onOpen: onOpenProperty
        )

        Section {
            EditionEntityPropertyButton(property: .series, properties: edit.properties, placeholder: "edit_work.series.placeholder", onOpen: onOpenProperty)
            EditionLiteralField(property: .seriesOrdinal, properties: $edit.properties, placeholder: "edit_work.series_ordinal.placeholder")
        } header: {
            CreateBookSectionHeader("edit_work.series.header")
        } footer: {
            CreateBookSectionFooter("edit_work.series.footer")
        }

        EditEntityPropertiesSection(
            properties: [.genre, .mainSubject],
            values: edit.properties,
            header: "edit_work.subjects.header",
            footer: "edit_work.subjects.footer",
            onOpen: onOpenProperty
        )

        EditEntityPropertiesSection(
            properties: EditionProperty.workRelations,
            values: edit.properties,
            header: "edit_work.relations.header",
            footer: "edit_work.relations.footer",
            onOpen: onOpenProperty
        )

        EditionIdentifiersSection(group: .databases, properties: $edit.properties, footer: "edit_work.databases.footer") {
            onAddIdentifier(.databases)
        }

        EditionIdentifiersSection(group: .links, properties: $edit.properties) {
            onAddIdentifier(.links)
        }

        EditEntityPropertiesSection(
            properties: [.workDifferentFrom],
            values: edit.properties,
            header: "edit_entity.misc.header",
            footer: "edit_work.misc.footer",
            onOpen: onOpenProperty
        )
    }
}
