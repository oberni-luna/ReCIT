//
//  WikidataEditNotice.swift
//  ReCIT_iOS
//
//  The line at the head of « Modifier l'œuvre » and « Modifier l'auteur·ice » for a work or a
//  person of Wikidata's (`W5` in the Figma file): « Enregistrer » publishes on Wikidata, and
//  under whose name — the reader's Wikidata account when it is linked, inventaire.io's bot
//  naming their account otherwise, with where to link it.
//

import SwiftUI

struct WikidataEditNotice: View {
    @Environment(UserModel.self) private var userModel

    private var text: LocalizedStringKey {
        userModel.account?.linksWikidata == true ? "edit_entity.wikidata.linked" : "edit_entity.wikidata.bot"
    }

    var body: some View {
        Section {
            Text(text)
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .listRowInsets(leading: .medium, trailing: .medium)
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("e2e.editEntity.wikidataNotice")
        }
    }
}
