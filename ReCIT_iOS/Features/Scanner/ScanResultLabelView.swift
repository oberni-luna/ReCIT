//
//  ScanResultLabelView.swift
//  ReCIT_iOS
//
//  The two lines of text in the scanner's result row, and the one place where each outcome
//  is put into words. What the row *says* is the whole of three of the states: an unknown
//  edition and a book already owned look identical to a failed scan if the row stays silent,
//  and a user who cannot tell those apart re-aims at a book that will never resolve and
//  concludes the scanner is broken.
//
//  The caption doubles as the book's authors when there is nothing else to report, so the
//  layout is the same two lines throughout and nothing jumps between states.
//
//  See PRD 0005.
//

import SwiftUI

struct ScanResultLabelView: View {
    let state: BatchScanState

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            Text(title)
                .textStyle(.content400Bold)
                .foregroundStyle(ScanOverlayPalette.ink)
                .lineLimit(2)
                // The title alone, for the end-to-end scenario's report: the row as a whole
                // reads out its fifteen contributors too, which is not a line anybody wants in
                // a compte-rendu.
                .accessibilityIdentifier("e2e.scan.title")

            caption
                .textStyle(.footnote200)
                .foregroundStyle(captionColor)
                // Two lines: the unknown-edition sentence is longer than an author's name and
                // truncating it would cost the row its only explanation.
                .lineLimit(2)
        }
    }

    /// The scanned code stands in as the title when no edition was found — it is the only
    /// thing known about the book, and it is what the user can check against the barcode in
    /// their hand.
    private var title: String {
        if case .notFound(let code) = state {
            code
        } else {
            (state.book ?? .placeholder).title
        }
    }

    private var caption: Text {
        switch state {
        case .idle, .lookingUp, .resolved, .adding:
            Text((state.book ?? .placeholder).authorsLine)
        case .notFound:
            Text("edition.no_result")
        case .alreadyOwned:
            Text("edition.my_inventory")
        case .added:
            Text("edition.added_to_inventory")
        }
    }

    /// The caption changes colour when it stops being part of the book and becomes the row
    /// talking: green for what went right, red for the edition inventaire does not have.
    private var captionColor: Color {
        switch state {
        case .idle, .lookingUp, .resolved, .adding:
            ScanOverlayPalette.ink
        case .notFound:
            ScanOverlayPalette.alert
        case .alreadyOwned, .added:
            ScanOverlayPalette.tint
        }
    }
}
