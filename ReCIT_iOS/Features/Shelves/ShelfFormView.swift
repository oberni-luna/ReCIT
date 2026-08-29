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
//  **A third mode writes nothing.** Handed a `ShelfDraftRequest`, the same form returns a
//  name to its caller instead of calling `ShelfModel` at all — that is how the sorting
//  surface's « + » adds an étagère to a stack that has not been saved yet, and it is the
//  one behavioural difference from the carousel's create action, which is untouched
//  (PRD 0008). The mode is a single optional value rather than a pair of flags, so the two
//  cannot be half-set, and `submit()` reads it first: there is no path from drafting into
//  a write.
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

    /// Set only when the form must **not** write: it hands the name back instead. See the
    /// note at the top of the file.
    private let draft: ShelfDraftRequest?

    @State private var name: String
    @State private var shelfDescription: String
    @State private var visibility: FormVisibility
    @State private var isConfirmingDelete: Bool = false

    init(shelf: Shelf? = nil, onDeleted: (() -> Void)? = nil) {
        self.shelf = shelf
        self.onDeleted = onDeleted
        draft = nil
        _name = State(initialValue: shelf?.name ?? "")
        _shelfDescription = State(initialValue: shelf?.shelfDescription ?? "")
        _visibility = State(initialValue: FormVisibility(raw: shelf?.visibility ?? []))
    }

    /// The non-writing form. There is nothing to edit and nothing to delete in this mode:
    /// a draft is a name, and it does not exist yet.
    init(draft: ShelfDraftRequest) {
        shelf = nil
        onDeleted = nil
        self.draft = draft
        _name = State(initialValue: "")
        _shelfDescription = State(initialValue: "")
        _visibility = State(initialValue: .private)
    }

    private var isEditing: Bool { shelf != nil }
    private var isDrafting: Bool { draft != nil }

    /// Why the typed name cannot be created, or `nil` when it can. Only drafting asks:
    /// the server does not enforce unique shelf names, so refusing one on the carousel
    /// would be inventing a rule the rest of the app does not keep. Here the rule earns
    /// itself — the whole stack is applied in one gesture, and two étagères the user
    /// reads as the same would be created by that one gesture.
    private var nameRefusal: SortDraftNameRule.Refusal? {
        draft?.nameRule.refusal(for: name)
    }

    private var canSubmit: Bool {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return false }
        return nameRefusal == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom de l'étagère", text: $name)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .accessibilityIdentifier("e2e.shelfForm.name")

                    // A draft carries a name and nothing else: the change stack has no
                    // room for a description or a visibility, and the étagère is
                    // eventually created with the same defaults this form produces. A
                    // field whose value would be quietly thrown away is worse than an
                    // absent one, so drafting asks for the name alone.
                    if isDrafting == false {
                        TextField("Description (optionnel)", text: $shelfDescription, axis: .vertical)
                            .lineLimit(2...4)
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                    }
                } footer: {
                    // Said as the name is typed rather than on submit: the user is still
                    // looking at the field, and the shelf they collided with is named
                    // back to them in its own spelling — « Romans » refusing "romans" is
                    // otherwise unreadable.
                    if case .alreadyUsed(let takenName) = nameRefusal {
                        Text("manual_sort.create.name_taken \(takenName)")
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundError)
                    }
                }

                if isDrafting == false {
                    Section {
                        Picker("Visibilité", selection: $visibility) {
                            ForEach(FormVisibility.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .foregroundStyle(.foregroundDefault)
                    }
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
                        .accessibilityIdentifier("e2e.shelfForm.submit")

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
                            .accessibilityIdentifier("e2e.shelfForm.delete")
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
                    .accessibilityIdentifier("e2e.shelfForm.confirmDelete")
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

        // Read first, and returns: drafting never falls through to a write. The étagère
        // does not exist yet and will not until the whole stack is applied.
        if let draft {
            draft.onCreate(trimmedName)
            dismiss()
            return
        }

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
