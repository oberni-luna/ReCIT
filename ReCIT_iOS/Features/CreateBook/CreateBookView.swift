//
//  CreateBookView.swift
//  ReCIT_iOS
//
//  The form that turns a scan which found nothing into a contribution to inventaire.io.
//
//  A `.sheet` posed on the camera rather than a screen pushed into the flow's navigation
//  stack: that stack belongs to the book screen, which a scanned row can already open, and
//  the two paths must not braid. While the sheet is up the scanner accepts no barcode — not
//  by a lock of its own, but because the machine is still holding `.notFound`.
//
//  The ISBN is shown and not editable: it is the one fact the app is certain of, read off the
//  barcode a moment ago, and the whole form exists because the *rest* is unknown.
//
//  This is the skeleton (issue 0090). What it publishes, and how, arrives with issue 0091.
//
//  See PRD 0015.
//

import SwiftUI

struct CreateBookView: View {
    @Environment(\.dismiss) private var dismiss

    let isbn: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(isbn)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .accessibilityIdentifier("e2e.createBook.isbn")
                        .withLabel(label: "create_book.isbn")
                } footer: {
                    Text("create_book.public_notice")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .applyListBackground()
            .navigationTitle(String(localized: "create_book.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                    .accessibilityIdentifier("e2e.createBook.close")
                }
            }
        }
        .accessibilityIdentifier("e2e.createBook.sheet")
    }
}
