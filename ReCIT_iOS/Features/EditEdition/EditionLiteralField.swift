//
//  EditionLiteralField.swift
//  ReCIT_iOS
//
//  A single value typed in its row — a work's rank in its series. What the server would refuse
//  is not kept: digits only, a rank above zero.
//

import SwiftUI

struct EditionLiteralField: View {
    let property: EditionProperty
    @Binding var properties: EditionProperties
    let placeholder: LocalizedStringKey

    var body: some View {
        TextField(
            placeholder,
            text: Binding(
                get: { properties.literal(of: property)?.text ?? "" },
                set: { properties.setLiteral(property.literal(from: $0.filter(\.isNumber)), for: property) }
            )
        )
        .keyboardType(.numberPad)
        .textStyle(.content300)
        .foregroundStyle(.foregroundDefault)
        .withLabel(label: property.label)
        .accessibilityIdentifier("e2e.editEntity.\(property.uri)")
    }
}
