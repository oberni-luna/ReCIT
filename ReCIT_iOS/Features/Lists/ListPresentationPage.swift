//
//  ListPresentationPage.swift
//  ReCIT_iOS
//
//  A list's Présentation tab: its description, whole, in one card — the list's own words, so in
//  the text's colour, an address in it opening — then a card of what the list is: its type, who
//  may see it, the day it was made and the day it last changed. The same for a friend's list as
//  for mine; editing stays behind the navigation bar's pencil. See the `Liste détails ·
//  Description de la liste` section of the Figma file (`909:1676`, B2).
//

import SwiftUI

struct ListPresentationPage: View {
    let list: EntityList

    var body: some View {
        if list.isStillInTheStore {
            if list.explanation.isEmpty == false {
                Section {
                    Text(UserPresentationTab.linked(list.explanation))
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            } else {
                Section {
                    EmptyStateView(
                        glyph: "text.quote",
                        title: "list.presentation.empty"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .large)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                Text(list.type.label)
                    .infoRow(label: "list.info.type")

                Text(ListVisibilityLabel.label(for: list.visibility))
                    .infoRow(label: "list.info.visibility")

                Text(list.created, format: .dateTime.day().month(.wide).year())
                    .infoRow(label: "list.info.created")

                if let updated = list.updated {
                    Text(updated, format: .dateTime.day().month(.wide).year())
                        .infoRow(label: "list.info.updated")
                }
            }
            .listRowSeparator(.visible)
            .listSectionSeparator(.hidden)
        }
    }
}

private extension View {
    /// A value under its caption, as in the list's form.
    func infoRow(label: String) -> some View {
        textStyle(.content300)
            .foregroundStyle(.foregroundDefault)
            .withLabel(label: label)
    }
}
