//
//  EditionTextValuesRows.swift
//  ReCIT_iOS
//
//  The free-text values of one property — a person's pseudonyms — each on a row it is swiped
//  off, then a field that adds one. What is typed there is added on « Retour » and when the
//  field loses focus, so tapping « Enregistrer » straight after typing does not lose it.
//

import SwiftUI

struct EditionTextValuesRows: View {
    let property: EditionProperty
    @Binding var properties: EditionProperties
    let addPlaceholder: LocalizedStringKey

    @State private var newValue: String = ""
    @FocusState private var isFocused: Bool

    private var values: [ClaimLiteral] {
        properties.values(of: property).compactMap(\.claim)
    }

    var body: some View {
        ForEach(Array(values.enumerated()), id: \.element) { index, value in
            Text(value.text)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .withLabel(label: index == 0 ? property.label : nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .swipeActions(edge: .trailing) {
                    Button("edit_edition.remove", role: .destructive) {
                        properties.remove(atOffsets: [index], from: property)
                    }
                    .tint(.foregroundError)
                }
        }

        TextField(addPlaceholder, text: $newValue)
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit(add)
            .onChange(of: isFocused) { _, focused in
                if focused == false { add() }
            }
            .textStyle(.content300)
            .foregroundStyle(.foregroundDefault)
            .withLabel(label: values.isEmpty ? property.label : nil)
            .accessibilityIdentifier("e2e.editEntity.\(property.uri).add")
    }

    private func add() {
        guard let literal = property.literal(from: newValue) else { return }
        properties.addLiteral(literal, to: property)
        newValue = ""
    }
}
