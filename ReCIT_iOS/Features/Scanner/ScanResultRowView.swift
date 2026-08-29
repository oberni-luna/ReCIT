//
//  ScanResultRowView.swift
//  ReCIT_iOS
//
//  The book that rises over the camera feed. Not `InventoryCell`: the design hides that
//  cell's subtitle, tag and owner, adds a 56pt trailing action, and resolves every colour to
//  its dark value. It is an overlay chip for a camera feed, not a list row on a light
//  surface — hence its own view and `ScanOverlayPalette`.
//
//  While the edition is being looked up the row draws the placeholder book redacted, at the
//  exact final layout, so nothing jumps when the real title arrives. Redaction needs content
//  to redact: an empty string greys out to nothing, which is why `ScannedBook.placeholder`
//  carries plausible strings that are never meant to be read.
//
//  What each outcome says is `ScanResultLabelView`'s; what can be done about it is this
//  view's — the add is dropped outright for an unknown edition and disabled for a book
//  already owned.
//
//  See PRD 0005.
//

import SwiftUI

struct ScanResultRowView: View {
    let state: BatchScanState
    let onOpen: (ScannedBook) -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: .sMedium) {
            ScanResultCoverView(imageUrl: displayedBook.coverImageUrl)

            // The text is the old single-shot scan's use, preserved: it opens the full book
            // screen without taking the camera down.
            Button {
                onOpen(displayedBook)
            } label: {
                ScanResultLabelView(state: state)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e.scan.row")
            .disabled(opensBook == false)

            // An edition inventaire does not have is the one row with no action at all:
            // there is nothing to file, and a disabled "+" would invite tapping at it.
            if offersAdd {
                ScanAddButton(state: state, action: onAdd)
            }
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .small)
        .redacted(reason: isLookingUp ? .placeholder : [])
        // The row's colours are its own, but the reused design-system button style reads the
        // appearance: pinning it dark makes it resolve the way the capture did, on the feed.
        .environment(\.colorScheme, .dark)
    }

    private var displayedBook: ScannedBook {
        state.book ?? .placeholder
    }

    private var isLookingUp: Bool {
        if case .lookingUp = state {
            true
        } else {
            false
        }
    }

    /// There is a book screen to open whenever a canonical uri was resolved — including for a
    /// book already owned, where looking it up is the obvious next thing to want.
    private var opensBook: Bool {
        displayedBook.uri.isEmpty == false
    }

    private var offersAdd: Bool {
        if case .notFound = state {
            false
        } else {
            true
        }
    }
}
