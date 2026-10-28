//
//  EditEntityPropertiesSection.swift
//  ReCIT_iOS
//
//  A section of rows whose values are entities — a work's roles, its relations, a person's
//  influences — each pushing its list of values, or the search when it names nobody yet.
//

import SwiftUI

struct EditEntityPropertiesSection: View {
    let properties: [EditionProperty]
    let values: EditionProperties
    let header: LocalizedStringKey
    let footer: LocalizedStringKey
    let onOpen: (EditionProperty) -> Void

    var body: some View {
        Section {
            ForEach(properties) { property in
                EditionEntityPropertyButton(
                    property: property,
                    properties: values,
                    placeholder: "edition_property.person.placeholder",
                    onOpen: onOpen
                )
            }
        } header: {
            CreateBookSectionHeader(header)
        } footer: {
            CreateBookSectionFooter(footer)
        }
    }
}
