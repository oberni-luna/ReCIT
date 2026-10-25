//
//  EditEditionAddedAuthorRow.swift
//  ReCIT_iOS
//
//  An author added to the edition's work, not saved yet: the name, and under it what tells them
//  apart — the search's description for someone inventaire.io has, or that they will be created
//  for someone it does not.
//

import SwiftUI

struct EditEditionAddedAuthorRow: View {
    let author: NewBookAuthor

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text(author.trimmedName)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)

            if author.uri == nil {
                Text("edit_edition.work.new_author")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            } else if let description = author.description, description.isEmpty == false {
                Text(description)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
