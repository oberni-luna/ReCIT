//
//  ShelfFormView.swift
//  ReCIT_iOS
//
//  Sheet to create or edit an étagère (name, description, visibility). Create fires an
//  optimistic POST; edit fires an optimistic update. See ADR 0004 / PRD 0001.
//

import SwiftUI

struct ShelfFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(UserModel.self) private var userModel

    /// `nil` when creating; an existing shelf when editing.
    private let shelf: Shelf?

    @State private var name: String
    @State private var shelfDescription: String
    @State private var visibility: FormVisibility

    init(shelf: Shelf? = nil) {
        self.shelf = shelf
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
                    Button {
                        submit()
                    } label: {
                        Text(isEditing ? "Enregistrer" : "Créer").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary())
                    .disabled(!canSubmit)
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
