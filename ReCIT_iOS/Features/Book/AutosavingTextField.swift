//
//  AutosavingTextField.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// A labelled multi-line field that hands its text to `save` after a pause in typing, on focus
/// loss, and on leaving the screen. `save` decides whether the text changed.
struct AutosavingTextField: View {
    /// How long typing must pause before the text is saved.
    private static let autosaveDelay: Duration = .seconds(1)

    private let label: LocalizedStringResource
    private let placeholder: LocalizedStringKey
    private let value: String
    private let identifier: String
    private let focus: FocusState<InventoryItemTextAttribute?>.Binding
    private let field: InventoryItemTextAttribute
    private let save: (String) -> Void

    @State private var draft: String

    init(
        _ label: LocalizedStringResource,
        placeholder: LocalizedStringKey,
        value: String,
        identifier: String,
        focus: FocusState<InventoryItemTextAttribute?>.Binding,
        field: InventoryItemTextAttribute,
        save: @escaping (String) -> Void
    ) {
        self.label = label
        self.placeholder = placeholder
        self.value = value
        self.identifier = identifier
        self.focus = focus
        self.field = field
        self.save = save
        _draft = State(initialValue: value)
    }

    private var isFocused: Bool {
        focus.wrappedValue == field
    }

    var body: some View {
        TextField(
            placeholder,
            text: $draft,
            axis: .vertical
        )
        .textStyle(.content300)
        .foregroundStyle(.foregroundDefault)
        .accessibilityIdentifier(identifier)
        .withLabel(label: String(localized: label))
        .focused(focus, equals: field)
        .onChange(of: isFocused) { _, focused in
            if !focused {
                save(draft)
            }
        }
        .task(id: draft) {
            // Autosave: a vertical field has no return key to end editing, so waiting
            // for focus loss alone left the note unsaved. Each keystroke restarts the wait.
            try? await Task.sleep(for: Self.autosaveDelay)
            guard !Task.isCancelled else { return }
            save(draft)
        }
        .onDisappear {
            // Leaving the screen cancels the pending autosave; flush it.
            save(draft)
        }
        .onChange(of: value) { _, newValue in
            // Keep the field in sync with background syncs / optimistic
            // reverts, but never clobber what the user is currently typing.
            if !isFocused {
                draft = newValue
            }
        }
    }
}

#Preview {
    @Previewable @FocusState var focus: InventoryItemTextAttribute?

    List {
        Section("edition.my_inventory") {
            AutosavingTextField(
                "inventory.item.private_note",
                placeholder: "inventory.item.write_private_note",
                value: "",
                identifier: "preview.privateNote",
                focus: $focus,
                field: .notes,
                save: { _ in }
            )
        }
    }
}
