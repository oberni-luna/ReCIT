//
//  IdentifierInputView.swift
//  ReCIT_iOS
//
//  Typing one identifier or link, checked as it is typed against the pattern the server checks
//  it with — so a value refused would have been refused there, with a less useful message.
//

import SwiftUI

struct IdentifierInputView: View {
    let property: EditionProperty
    let onAdd: (ClaimLiteral) -> Void

    @State private var text: String = ""

    private var literal: ClaimLiteral? {
        property.literal(from: text)
    }

    private var name: String {
        String(localized: String.LocalizationValue(property.label))
    }

    var body: some View {
        Form {
            Section {
                TextField(property.example ?? "", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(property.kind == .url ? .URL : .asciiCapable)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: property.label)
                    .accessibilityIdentifier("e2e.editEdition.identifier")
            } footer: {
                if text.isEmpty == false, literal == nil {
                    Text("edit_edition.identifiers.invalid \(name)")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundError)
                } else if let example = property.example {
                    Text("edit_edition.identifiers.example \(example)")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }

            Section {} footer: {
                Button {
                    if let literal { onAdd(literal) }
                } label: {
                    Text("edit_edition.identifiers.add")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary())
                .disabled(literal == nil)
                .accessibilityIdentifier("e2e.editEdition.identifier.add")
            }
        }
        .applyListBackground()
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
