//
//  ScanAddButton.swift
//  ReCIT_iOS
//
//  The row's trailing action: the whole feature in one 56pt disc. It files the book, shows a
//  loader in place of its glyph while the server is answering — the add waits rather than
//  being optimistic, see `BatchScanViewModel` — and turns into a checkmark for as long as the
//  confirmation is held.
//
//  The loader carries its own colour: the design-system disabled pair resolves to the same
//  grey in dark appearance, which would leave a spinner invisible on its own disc.
//

import SwiftUI

struct ScanAddButton: View {
    let state: BatchScanState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if case .adding = state {
                ProgressView()
                    .controlSize(.small)
                    .tint(ScanOverlayPalette.tint)
                    .foregroundStyle(ScanOverlayPalette.tint)
            } else {
                Label("action.add_to_inventory", systemImage: glyph)
                    .labelStyle(.iconOnly)
            }
        }
        .buttonStyle(.circularIcon)
        .disabled(isDisabled)
        .accessibilityLabel(Text("action.add_to_inventory"))
    }

    private var glyph: String {
        if case .added = state {
            "checkmark"
        } else {
            "plus"
        }
    }

    /// Disabled while there is nothing to file yet, while the add is in flight — so the same
    /// book cannot be filed twice by an impatient second tap — and for a book the inventory
    /// already holds, which is the whole of what that state does. `notFound` never gets this
    /// far: the row drops the action rather than disabling it.
    private var isDisabled: Bool {
        switch state {
        case .idle, .lookingUp, .notFound, .alreadyOwned, .adding:
            true
        case .resolved, .added:
            false
        }
    }
}
