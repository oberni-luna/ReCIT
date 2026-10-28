//
//  EntityLabelRows.swift
//  ReCIT_iOS
//
//  A work's title or a person's name, one field per language it has, then « Ajouter dans une
//  autre langue », a menu of the languages it has none in. The first rows of « Modifier
//  l'œuvre » and « Modifier l'auteur·ice ».
//

import SwiftUI

struct EntityLabelRows: View {
    @Binding var edit: EntityEdit
    /// A field's name for a language's name: « Titre · Français ».
    let fieldName: (String) -> String
    let addTitle: LocalizedStringKey

    var body: some View {
        ForEach($edit.labels) { $label in
            let name: String = fieldName(Self.languageName(label.language))

            TextField(name, text: $label.value)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .withLabel(label: name)
                .accessibilityIdentifier("e2e.editEntity.label.\(label.language)")
        }

        Menu {
            ForEach(edit.addableLanguages, id: \.self) { language in
                Button(Self.languageName(language)) {
                    edit.addLabel(language: language)
                }
            }
        } label: {
            Label(addTitle, systemImage: "plus")
                .textStyle(.content300)
                .foregroundStyle(.foregroundTinted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.editEntity.addLabel")
    }

    /// A language's name in the reader's language, « Français »; its code when the system has none.
    static func languageName(_ code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code)?.capitalized(with: .current) ?? code
    }
}
