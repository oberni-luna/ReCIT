//
//  BookBibliographicDataSection.swift
//  ReCIT_iOS
//
//  « Données bibliographiques » — the last section of the book screen: one row, which opens the
//  edition's form, and a sentence under it on what correcting the record is for. Frame `744:2383`
//  of the Figma section `Fiche livre · Données bibliographiques`, as retouched on 2026-10-25: a
//  `Row / Link` in `foreground/tinted`, the bare action row of the Profil, no glyph, no chevron,
//  and no section header — the row names the section itself.
//
//  Last, after the reader's own copy: what is on the screen is first the book and who has it,
//  and correcting the record of it is the rarer gesture. Offered for every edition but a
//  Wikidata one (`EditionClaims.canEdit(uri:)`), owned or not — inventaire.io's data are open
//  to every account.
//

import SwiftUI

struct BookBibliographicDataSection: View {
    let onEdit: () -> Void

    var body: some View {
        Section {
            Button("book.bibliographic_data", action: onEdit)
                .textStyle(.action300)
                .foregroundStyle(.foregroundTinted)
                .accessibilityIdentifier("e2e.book.editEdition")
        } footer: {
            Text("book.bibliographic_data.footer")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
        }
    }
}
