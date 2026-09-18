//
//  ScanCreateButton.swift
//  ReCIT_iOS
//
//  The trailing action of the one row that used to have none: an edition inventaire.io does
//  not have. It takes the exact place, size and disc of `ScanAddButton` — variant A of the
//  maquette — so the gesture is the same one the hand already knows from a book that resolved.
//
//  It wears a « + » like the add does, and that is a known weakness rather than an oversight:
//  the design system's `Icon` set has no `book.badge.plus`, and until it does the two actions
//  are told apart by their accessibility label alone. See the spec panel of the Figma section
//  `Créer un livre absent`, and PRD 0015.
//

import SwiftUI

struct ScanCreateButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("scanner.action.create_book", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.circularIcon)
        .accessibilityLabel(Text("scanner.action.create_book"))
        .accessibilityIdentifier("e2e.scan.create")
    }
}
