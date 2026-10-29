//
//  EditEntityView.swift
//  ReCIT_iOS
//
//  « Modifier l'œuvre » and « Modifier l'auteur·ice », pushed over « Modifier l'édition »: the
//  work or the person read fresh from inventaire.io, its form, and its own « Enregistrer »
//  pinned at the foot (Figma `814:5090`, decided on 2026-10-28). Saving sends this entity alone,
//  then goes back one screen; what was being changed beneath stays as it was.
//
//  Going back over changes not saved asks « Quitter sans enregistrer ? », as « Ranger mes
//  livres » does (feature 0032): the system's back button is replaced while there is something
//  to lose, which also takes the edge swipe away.
//
//  The edit lives in the flow that pushed the screen, so the screens this one pushes — a
//  search, a date, a list — write into it.
//

import SwiftUI

struct EditEntityView: View {
    @Environment(EntityCreationModel.self) private var creationModel

    let uri: String
    @Binding var edit: EntityEdit?

    /// What went wrong at the last save, in the reader's terms. `nil` until something does.
    let failure: CreateBookFailure?

    let onSave: () async -> Void
    /// Goes back without saving: the changes are dropped.
    let onLeave: () -> Void
    let onOpenProperty: (EditionProperty) -> Void
    let onPick: (EditionProperty) -> Void
    let onAddIdentifier: (EditionProperty.Group) -> Void
    let onOpenEntity: (String) -> Void

    @State private var hasFailedToLoad: Bool = false
    /// Bumped by « Réessayer » when the entity could not be read: the `.task` key.
    @State private var attempt: Int = 0
    @State private var isConfirmingLeave: Bool = false

    private var hasChanges: Bool {
        edit?.hasChanges == true
    }

    private var title: String {
        switch edit?.catalogue {
        case .human: String(localized: "edit_author.title")
        default: String(localized: "edit_work.title")
        }
    }

    var body: some View {
        Group {
            if let binding = Binding($edit) {
                DesignSystem.Form {
                    if let failure {
                        Section {
                            CreateBookFailureBanner(
                                title: failure.editionEditTitle,
                                explanation: failure.entityEditExplanation
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listSectionSeparator(.hidden)
                    }

                    form(binding)
                }
            } else if hasFailedToLoad {
                BookAbsenceView(absence: .failed) { attempt += 1 }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .formActionBar(isPresented: edit?.isEditable == true) {
            EditEditionSaveBar(
                title: failure?.isWorthRetrying == true ? "create_book.retry" : "action.save",
                isEnabled: edit?.isSaveable == true,
                onSave: onSave
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(hasChanges)
        .toolbar {
            if hasChanges {
                ToolbarItem(placement: .topBarLeading) {
                    Button("action.back", systemImage: "chevron.left") {
                        isConfirmingLeave = true
                    }
                    .accessibilityIdentifier("e2e.editEntity.back")
                }
            }
        }
        // Not destructive in the platform's sense: what is dropped was never sent. The question
        // is whether the reader knows it is not saved, so the answer is « Quitter ».
        .confirmationDialog(
            "manual_sort.leave.confirm.title",
            isPresented: $isConfirmingLeave,
            titleVisibility: .visible
        ) {
            Button("manual_sort.leave.confirm.action", action: onLeave)
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text("edit_entity.leave.message")
        }
        .bibliographicDataHelpButton()
        .task(id: attempt) {
            await load()
        }
    }

    @ViewBuilder
    private func form(_ binding: Binding<EntityEdit>) -> some View {
        switch binding.wrappedValue.catalogue {
        case .work:
            EditWorkFormView(
                edit: binding,
                onOpenProperty: onOpenProperty,
                onPick: onPick,
                onAddIdentifier: onAddIdentifier,
                onOpenEntity: onOpenEntity
            )
        case .human:
            EditAuthorFormView(
                edit: binding,
                onOpenProperty: onOpenProperty,
                onAddIdentifier: onAddIdentifier
            )
        case .edition:
            EmptyView()
        }
    }

    /// Reads the entity, unless the flow holds it already — coming back from a screen it pushed.
    private func load() async {
        guard edit == nil else { return }
        hasFailedToLoad = false
        do {
            edit = try await creationModel.editableEntity(uri: uri)
        } catch {
            hasFailedToLoad = true
        }
    }
}
