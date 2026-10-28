//
//  EditionChoiceListView.swift
//  ReCIT_iOS
//
//  The values a property allows, when they are too many for a menu: a work's thirty-one forms.
//  Touching one sets it and goes back; « Aucune » takes it away.
//

import SwiftUI

struct EditionChoiceListView: View {
    @Environment(\.dismiss) private var dismiss

    let property: EditionProperty
    @Binding var properties: EditionProperties

    private var selected: String? {
        properties.literal(of: property)?.string
    }

    var body: some View {
        DesignSystem.FormList {
            Section {
                ForEach(property.choices) { choice in
                    EditionChoiceListRow(
                        title: String(localized: String.LocalizationValue(choice.label)),
                        isSelected: selected == choice.uri
                    ) {
                        properties.setLiteral(.string(choice.uri), for: property)
                        dismiss()
                    }
                }

                EditionChoiceListRow(
                    title: String(localized: "edition_choice.none"),
                    isSelected: selected == nil
                ) {
                    properties.setLiteral(nil, for: property)
                    dismiss()
                }
            }
        }
        .navigationTitle(String(localized: String.LocalizationValue(property.label)))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("e2e.editEntity.choices")
    }
}

/// One value, checked when it is the property's.
private struct EditionChoiceListRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .small) {
                Text(title)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.foregroundTinted)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
