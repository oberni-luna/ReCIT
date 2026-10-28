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
    /// The catalogue of the form it was pushed from: an edition's, a work's, a person's.
    var catalogue: EditionProperty.Catalogue = .edition
    let onChoose: (EditionProperty) -> Void

    var body: some View {
        DesignSystem.FormList {
            Section {
                ForEach(catalogue.properties(in: group)) { property in
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
        .navigationTitle(String(localized: group == .databases ? "edit_edition.databases.add" : "edit_edition.links.add"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
