//
//  LinkSheet.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// The screen an Ex-libris link names, opened over a modal rather than under it (issue 143): a
/// stack of its own with the screen at its root, so that what it pushes stays in it, and
/// « Fermer » back to the modal as it was.
///
/// A focus of its own, with its veil, as the Profil sheet has: a reader's étagères are pressed
/// here too, and the tab view's veil would sit underneath.
struct LinkSheet: View {
    private let destination: NavigationDestination

    @State private var path: NavigationPath = .init()

    @Environment(\.dismiss) private var dismiss: DismissAction

    init(_ destination: NavigationDestination) {
        self.destination = destination
    }

    var body: some View {
        NavigationStack(path: $path) {
            destination.viewForDestination($path)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destination.viewForDestination($path)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("action.close", systemImage: "xmark") {
                            dismiss()
                        }
                        .accessibilityIdentifier(AccessibilityID.close)
                    }
                }
        }
        .ownsShelfFocus()
    }
}

private extension LinkSheet {
    enum AccessibilityID {
        static let close: String = "e2e.linkSheet.close"
    }
}

#Preview {
    LinkSheet(.aboutInventaire)
}
