//
//  EditEntityPersonRow.swift
//  ReCIT_iOS
//
//  One author of a work in « Modifier l'œuvre »: their name, and — when they exist, on
//  inventaire.io or on Wikidata — a chevron to « Modifier l'auteur·ice ». One still to be created
//  is created with the work's save.
//

import SwiftUI

struct EditEntityPersonRow: View {
    let person: EditionEntityValue
    let onOpen: (String) -> Void

    var body: some View {
        if let uri = person.uri, EntityEdit.canEdit(uri: uri) {
            Button {
                onOpen(uri)
            } label: {
                HStack(spacing: .small) {
                    EditWorkAuthorRow(author: author)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.foregroundSecondary)
                        .accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e.editWork.author")
        } else {
            EditWorkAuthorRow(author: author)
        }
    }

    private var author: NewBookAuthor {
        .init(id: person.id, name: person.label, uri: person.uri, description: person.detail)
    }
}
