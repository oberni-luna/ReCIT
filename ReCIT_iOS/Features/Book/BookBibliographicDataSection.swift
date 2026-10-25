//
//  BookBibliographicDataSection.swift
//  ReCIT_iOS
//
//  « Données bibliographiques » — the last section of the book screen, and its one row,
//  « Modifier », which opens the edition's form. Frames `744:2383` and `744:2482` of the Figma
//  section `Fiche livre · Données bibliographiques`: a `Row / Link` in `foreground/tinted`, the
//  bare action row of the Profil, no glyph and no chevron.
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
        Section("book.bibliographic_data") {
            Button("action.edit", action: onEdit)
                .textStyle(.action300)
                .foregroundStyle(.foregroundTinted)
                .accessibilityIdentifier("e2e.book.editEdition")
        }
    }
}
