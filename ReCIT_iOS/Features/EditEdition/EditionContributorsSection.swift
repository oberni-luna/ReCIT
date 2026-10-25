//
//  EditionContributorsSection.swift
//  ReCIT_iOS
//
//  « Ont aussi fait cette édition »: the people this edition credits besides the work's authors —
//  translation, illustrations, cover, preface, afterword, editorial direction. Each role can name
//  several people, chosen on inventaire.io or created.
//

import SwiftUI

struct EditionContributorsSection: View {
    let properties: EditionProperties
    let onOpen: (EditionProperty) -> Void

    var body: some View {
        Section {
            ForEach(EditionProperty.contributors) { property in
                EditionEntityPropertyButton(
                    property: property,
                    properties: properties,
                    placeholder: "edition_property.person.placeholder",
                    onOpen: onOpen
                )
            }
        } header: {
            CreateBookSectionHeader("edit_edition.contributors.header")
        } footer: {
            CreateBookSectionFooter("edit_edition.contributors.footer")
        }
    }
}
