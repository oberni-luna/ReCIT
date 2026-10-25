//
//  EditEditionActionRow.swift
//  ReCIT_iOS
//
//  A row of « Édition de » that leads somewhere: « Ajouter un·e auteur·ice », « Choisir
//  l'œuvre ». A « + » and a tinted label, as the search's « Créer l'œuvre » row draws it.
//

import SwiftUI

struct EditEditionActionRow: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus")
                .textStyle(.content300)
                .foregroundStyle(.foregroundTinted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
