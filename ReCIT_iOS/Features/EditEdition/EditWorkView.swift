//
//  EditWorkView.swift
//  ReCIT_iOS
//
//  « Modifier l'œuvre » — one work of the edition, pushed from « Édition de »: its title and its
//  authors, filled with what the row showed. The shape of `V5 · Nouvelle œuvre` in the Figma
//  file (`E5`), and the only place a work's authors change: an author belongs to the work, for
//  every edition of it, not to the edition the reader holds.
//
//  Nothing is sent from here. What changes goes with the sheet's « Enregistrer », on the way
//  back: one save for the whole form. A Wikidata work is shown and not changed — its title and
//  authors are edited on Wikidata.
//

import SwiftUI

struct EditWorkView: View {
    @Binding var work: WorkEdit
    /// Pushes the search for an author to add.
    let onAddAuthor: () -> Void

    private var footer: LocalizedStringKey {
        if work.isEditable == false { return "edit_work.wikidata_help" }
        if work.isNew { return "edit_work.new_help" }
        return "edit_work.help"
    }

    var body: some View {
        DesignSystem.Form {
            Section {
                TextField("create_book.new_work.title_field", text: $work.title)
                    .disabled(work.isEditable == false)
                    .accessibilityIdentifier("e2e.editWork.title")
                    .textStyle(.content300)
                    .foregroundStyle(work.isEditable ? .foregroundDefault : .foregroundSecondary)
                    .withLabel(label: "create_book.new_work.title_field")

                ForEach(work.authors) { author in
                    EditWorkAuthorRow(author: author)
                }
                .onDelete { offsets in
                    work.removeAuthors(atOffsets: offsets)
                }
                .deleteDisabled(work.isEditable == false)

                if work.isEditable {
                    EditEditionActionRow(
                        title: work.authors.isEmpty ? "edit_edition.work.add_author" : "edit_work.add_other_author",
                        action: onAddAuthor
                    )
                    .accessibilityIdentifier("e2e.editWork.addAuthor")
                }
            } header: {
                CreateBookSectionHeader("edit_work.header")
            } footer: {
                CreateBookSectionFooter(footer)
            }
        }
        .navigationTitle(String(localized: work.isNew ? "create_book.new_work.title" : "edit_work.title"))
        .navigationBarTitleDisplayMode(.inline)
        .bibliographicDataHelpButton()
    }
}
