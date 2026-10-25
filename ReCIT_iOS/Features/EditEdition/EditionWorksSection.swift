//
//  EditionWorksSection.swift
//  ReCIT_iOS
//
//  « Édition de » in « Modifier l'édition »: the works the edition is an edition of — one, or
//  several for a collection of works — then « Ajouter une œuvre ». Touching a work opens
//  « Modifier l'œuvre », the only place its title and authors change; swiping it to the left
//  detaches it from the edition (`E4` of the Figma section). The work itself stays on
//  inventaire.io.
//

import SwiftUI

struct EditionWorksSection: View {
    let works: [WorkEdit]
    /// Pushes « Modifier l'œuvre » for the work with this id.
    let onOpen: (UUID) -> Void
    let onDetach: (UUID) -> Void
    /// Pushes the work search.
    let onAdd: () -> Void

    private var footer: LocalizedStringKey {
        if works.isEmpty { return "edit_edition.works.empty_help" }
        if works.contains(where: { $0.isNew && $0.authors.isEmpty }) { return "edit_edition.works.new_help" }
        return "edit_edition.works.help"
    }

    var body: some View {
        Section {
            ForEach(works) { work in
                Button {
                    onOpen(work.id)
                } label: {
                    WorkRow(work: work.candidate, showsDisclosure: true)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button("edit_edition.works.detach", role: .destructive) {
                        onDetach(work.id)
                    }
                    // The app's tint would otherwise paint it pale green, its label unreadable.
                    .tint(.foregroundError)
                }
                .accessibilityIdentifier("e2e.editEdition.work")
            }

            EditEditionActionRow(title: "edit_edition.works.add", action: onAdd)
                .accessibilityIdentifier("e2e.editEdition.addWork")
        } header: {
            CreateBookSectionHeader("create_book.edition.of")
        } footer: {
            CreateBookSectionFooter(footer)
        }
    }
}
