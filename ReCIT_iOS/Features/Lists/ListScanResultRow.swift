//
//  ListScanResultRow.swift
//  ReCIT_iOS
//
//  The book that rises over the list's scanner: its cover, its title and authors, and the round
//  « + » that adds it to the list. The batch scanner's row, minus what only an inventory needs —
//  no book screen behind the text, no « create this book », no « already in my inventory ».
//
//  A book the lookup could not find shows its ISBN, « Introuvable pour l’instant », and a round
//  « Réessayer » in place of the « + »: the lookup fails on a cold path more often than the book
//  is missing, and the same barcode in frame is gated, so the button is the only way to ask again.
//  A different barcode still takes the row.
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
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: .sMedium) {
            ScanResultCoverView(imageUrl: (state.book ?? .placeholder).coverImageUrl)

            ScanResultLabelView(state: state)
                .notFoundCaption("list.add.not_found")
                .frame(maxWidth: .infinity, alignment: .leading)

            if isNotFound {
                Button("list.add.retry", systemImage: "arrow.clockwise", action: onRetry)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.circularIcon)
                    .accessibilityIdentifier(AccessibilityID.retry)
            } else {
                Button("list.add.action", systemImage: "plus", action: onAdd)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.circularIcon)
                    .disabled(isResolved == false)
                    .accessibilityIdentifier(AccessibilityID.add)
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

private extension ListScanResultRow {
    enum AccessibilityID {
        static let add: String = "e2e.list.scan.add"
        static let retry: String = "e2e.list.scan.retry"
    }
}
