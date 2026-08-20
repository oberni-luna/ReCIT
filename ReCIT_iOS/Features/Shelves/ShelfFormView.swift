//
//  ShelfFormView.swift
//  ReCIT_iOS
//
//  Sheet to create or edit an étagère (name, description, visibility). Create fires an
//  optimistic POST; edit fires an optimistic update. See ADR 0004 / PRD 0001.
//
//  Edit mode also carries the only route to deleting an étagère: the shelf is already the
//  subject of this sheet, so the destructive action belongs at its foot rather than behind
//  a menu on the card or the carousel. See issue 0021.
//

import SwiftUI

struct ShelfFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(UserModel.self) private var userModel

    /// `nil` when creating; an existing shelf when editing.
    private let shelf: Shelf?

    /// Told to the presenter when the étagère is deleted, so a screen that stands for this
    /// shelf can leave with the sheet instead of outliving its subject.
    private let onDeleted: (() -> Void)?

    @State private var name: String
    @State private var shelfDescription: String
    @State private var visibility: FormVisibility
    @State private var isConfirmingDelete: Bool = false

    init(shelf: Shelf? = nil, onDeleted: (() -> Void)? = nil) {
        self.shelf = shelf
        self.onDeleted = onDeleted
        _name = State(initialValue: shelf?.name ?? "")
        _shelfDescription = State(initialValue: shelf?.shelfDescription ?? "")
        _visibility = State(initialValue: FormVisibility(raw: shelf?.visibility ?? []))
    }

    private var isEditing: Bool { shelf != nil }
    private var canSubmit: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom de l'étagère", text: $name)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)

                    TextField("Description (optionnel)", text: $shelfDescription, axis: .vertical)
                        .lineLimit(2...4)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                }

                Section {
                    Picker("Visibilité", selection: $visibility) {
                        ForEach(FormVisibility.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .foregroundStyle(.foregroundDefault)
                }

                Section {} footer: {
                    VStack {
                        Button {
                            submit()
                        } label: {
                            Text(isEditing ? "Enregistrer" : "Créer").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.primary())
                        .disabled(!canSubmit)

                        // Edit only. There is nothing to delete while creating, and a
                        // destructive button standing next to "Créer" would read as the
                        // way out of the form rather than the way out of an étagère.
                        if isEditing {
                            Button(role: .destructive) {
                                isConfirmingDelete = true
                            } label: {
                                Text("Supprimer l'étagère").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.destructive())
                        }
                    }
                }
            }
            .applyListBackground()
            .navigationTitle(isEditing ? "Modifier l'étagère" : "Nouvelle étagère")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
            }
            // The books are named before the shelf is: "supprimer l'étagère" is read as
            // "supprimer mes livres", and a user who has just scanned two hundred books
            // will not risk it on a dialog that leaves the question open.
            .confirmationDialog(
                "Supprimer cette étagère ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer l'étagère", role: .destructive) { delete() }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Vos livres sont conservés : ils restent dans votre inventaire et sur vos autres étagères. Seule l'étagère est supprimée.")
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        let trimmedName: String = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription: String = shelfDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if let shelf {
            shelfModel.updateShelf(
                shelf,
                name: trimmedName,
                description: trimmedDescription,
                visibility: visibility.raw,
                modelContext: modelContext
            )
        } else if let ownerId = userModel.myUser?._id {
            shelfModel.createShelf(
                name: trimmedName,
                description: trimmedDescription,
                visibility: visibility.raw,
                ownerId: ownerId,
                modelContext: modelContext
            )
        }
        dismiss()
    }

    /// The write is optimistic and model-owned, so the sheet can go straight away — the
    /// shelf is already off the carousel and the call outlives this view either way.
    /// `onDeleted` is signalled before dismissing, so the presenter can read it once the
    /// sheet has actually gone.
    private func delete() {
        guard let shelf else { return }
        shelfModel.deleteShelf(shelf, modelContext: modelContext)
        onDeleted?()
        dismiss()
    }
}

/// The three visibility choices offered in the form, mapped to inventaire's raw values.
enum FormVisibility: String, CaseIterable, Identifiable {
    case `private`
    case friends
    case `public`

    var id: Self { self }

    var label: String {
        switch self {
        case .private: return "Privé"
        case .friends: return "Amis"
        case .public: return "Public"
        }
    }

    var raw: [String] {
        switch self {
        case .private: return []
        case .friends: return ["friends"]
        case .public: return ["public"]
        }
    }

    init(raw: [String]) {
        if raw.contains("public") {
            self = .public
        } else if raw.contains("friends") {
            self = .friends
        } else {
            self = .private
        }
    }
}
