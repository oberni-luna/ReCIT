//
//  EditionEntityValuesView.swift
//  ReCIT_iOS
//
//  The entities one property of the edition names — its publishers, its translators — listed,
//  taken away with a swipe, and added to through the search. Pushed by a row that already
//  names someone; an empty row goes straight to the search. A person inventaire.io has opens
//  « Modifier l'auteur·ice » when touched, where the flow can push it.
//

import SwiftUI

struct EditionEntityValuesView: View {
    let property: EditionProperty
    @Binding var properties: EditionProperties
    /// Pushes the search for one more.
    let onAdd: () -> Void
    /// Pushes « Modifier l'auteur·ice » for the person with this uri. `nil` where it cannot be
    /// pushed.
    var onOpenEntity: ((String) -> Void)?

    var body: some View {
        DesignSystem.FormList {
            Section {
                ForEach(properties.entities(of: property)) { entity in
                    if let uri = openableUri(of: entity), let onOpenEntity {
                        Button {
                            onOpenEntity(uri)
                        } label: {
                            HStack(spacing: .small) {
                                EditionEntityValueLabel(entity: entity)

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.foregroundSecondary)
                                    .accessibilityHidden(true)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("e2e.editEdition.values.open")
                    } else {
                        EditionEntityValueLabel(entity: entity)
                    }
                }
                .onDelete { offsets in
                    properties.remove(atOffsets: offsets, from: property)
                }

                EditEditionActionRow(title: "edit_edition.values.add", action: onAdd)
                    .accessibilityIdentifier("e2e.editEdition.values.add")
            } footer: {
                CreateBookSectionFooter("edit_edition.values.footer")
            }
        }
        .navigationTitle(String(localized: String.LocalizationValue(property.label)))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The uri of a person inventaire.io has, whose screen can be pushed. A Wikidata person is
    /// changed on Wikidata, and one still to be created has nothing to open.
    private func openableUri(of entity: EditionEntityValue) -> String? {
        guard property.searchType == .humans, let uri = entity.uri, uri.hasPrefix("inv:") else { return nil }
        return uri
    }
}

/// One entity: its name, and what tells it apart — or that it is still to be created.
private struct EditionEntityValueLabel: View {
    let entity: EditionEntityValue

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text(entity.trimmedLabel)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)

            if entity.uri == nil {
                Text("edit_edition.work.new_author")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            } else if let detail = entity.detail, detail.isEmpty == false {
                Text(detail)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
