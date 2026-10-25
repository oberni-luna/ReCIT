//
//  IdentifierCatalogView.swift
//  ReCIT_iOS
//
//  The catalogues an edition can be identified in — or the kinds of links it can have — to pick
//  the one an identifier is added to. Pushed by « Ajouter un identifiant » and « Ajouter un
//  lien ».
//

import SwiftUI

struct IdentifierCatalogView: View {
    let group: EditionProperty.Group
    let onChoose: (EditionProperty) -> Void

    var body: some View {
        List {
            Section {
                ForEach(EditionProperty.properties(in: group)) { property in
                    Button {
                        onChoose(property)
                    } label: {
                        EditionPropertyRow(
                            label: property.label,
                            value: property.example,
                            placeholder: ""
                        )
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                CreateBookSectionFooter("edit_edition.identifiers.catalog_footer")
            }
        }
        .applyListBackground()
        .navigationTitle(String(localized: group == .databases ? "edit_edition.databases.add" : "edit_edition.links.add"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
