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
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(displayedBook.title)
                        .textStyle(.content400Bold)
                        .foregroundStyle(ScanOverlayPalette.ink)
                        .lineLimit(2)

                    if case .added = state {
                        Text("edition.added_to_inventory")
                            .textStyle(.footnote200)
                            .foregroundStyle(ScanOverlayPalette.tint)
                            .lineLimit(1)
                    } else {
                        Text(displayedBook.authorsLine)
                            .textStyle(.footnote200)
                            .foregroundStyle(ScanOverlayPalette.ink)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(isLookingUp)

            ScanAddButton(state: state, action: onAdd)
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
}
