//
//  EditionPropertyRow.swift
//  ReCIT_iOS
//
//  One property of the edition in « Modifier l'édition »: its name above, its value — or an
//  invitation in the placeholder colour — below, and at the trailing edge what touching it does.
//  `Form / Labeled Value` in the Figma file: Trailing=Chevron pushes a choice (a publisher, a
//  person, a language), Trailing=Menu opens a menu (the format), Trailing=None is a field.
//

import SwiftUI

struct EditionPropertyRow: View {

    enum Trailing {
        case none
        case chevron
        case menu
    }

    /// The catalogue key of the property's name.
    let label: String
    /// What the property holds, as the form prints it. `nil` shows `placeholder`.
    let value: String?
    let placeholder: LocalizedStringKey
    var trailing: Trailing = .chevron

    var body: some View {
        HStack(spacing: .small) {
            Group {
                if let value {
                    Text(value)
                        .foregroundStyle(.foregroundDefault)
                } else {
                    Text(placeholder)
                        .foregroundStyle(.foregroundPlaceholder)
                }
            }
            .textStyle(.content300)
            .withLabel(label: label)
            .frame(maxWidth: .infinity, alignment: .leading)

            switch trailing {
            case .none:
                EmptyView()
            case .chevron:
                Image(systemName: "chevron.right")
                    .foregroundStyle(.foregroundSecondary)
                    .accessibilityHidden(true)
            case .menu:
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.foregroundSecondary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(.rect)
    }
}
