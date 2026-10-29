//
//  ListScanResultRow.swift
//  ReCIT_iOS
//
//  The book that rises over the list's scanner: its cover, its title and authors, and the round
//  « + » that adds it to the list. The batch scanner's row, minus what only an inventory needs —
//  no book screen behind the text, no « create this book », no « already in my inventory ».
//
//  Its cover, its words and its colours are the batch scanner's (`ScanResultCoverView`,
//  `ScanResultLabelView`, `ScanOverlayPalette`), so the two scanners read as one.
//
//  See PRD 0029.
//

import SwiftUI

struct ListScanResultRow: View {
    let state: BatchScanState
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: .sMedium) {
            ScanResultCoverView(imageUrl: (state.book ?? .placeholder).coverImageUrl)

            ScanResultLabelView(state: state)
                .frame(maxWidth: .infinity, alignment: .leading)

            // An edition inventaire.io does not have, or one with no work, has nothing to add:
            // the row only says so, and the next barcode takes its place.
            if isNotFound == false {
                Button("list.add.action", systemImage: "plus", action: onAdd)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.circularIcon)
                    .disabled(isResolved == false)
                    .accessibilityIdentifier("e2e.list.scan.add")
            }
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .small)
        .redacted(reason: isLookingUp ? .placeholder : [])
        // The design-system button style reads the appearance: the row floats on a camera feed.
        .environment(\.colorScheme, .dark)
    }

    private var isResolved: Bool {
        if case .resolved = state {
            true
        } else {
            false
        }
    }

    private var isNotFound: Bool {
        if case .notFound = state {
            true
        } else {
            false
        }
    }

    private var isLookingUp: Bool {
        if case .lookingUp = state {
            true
        } else {
            false
        }
    }
}
