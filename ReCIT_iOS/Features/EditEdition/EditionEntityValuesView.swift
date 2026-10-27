//
//  EditionEntityValuesView.swift
//  ReCIT_iOS
//
//  The entities one property of the edition names — its publishers, its translators — listed,
//  taken away with a swipe, and added to through the search. Pushed by a row that already
//  names someone; an empty row goes straight to the search.
//

import SwiftUI

struct EditionEntityValuesView: View {
    let property: EditionProperty
    @Binding var properties: EditionProperties
    /// Pushes the search for one more.
    let onAdd: () -> Void

    var body: some View {
        DesignSystem.FormList {
            Section {
                ForEach(properties.entities(of: property)) { entity in
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
}
