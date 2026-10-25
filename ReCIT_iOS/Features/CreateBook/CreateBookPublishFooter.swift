//
//  CreateBookPublishFooter.swift
//  ReCIT_iOS
//
//  The foot of every screen that publishes: « Publier et ajouter à mes livres », and — once
//  something has failed — the way out that keeps the draft.
//
//  Publishing waits for the server, and the sheet stays open until it answers: nothing about
//  this write is optimistic, `EntityCreationModel` says why at length.
//
//  See PRD 0015 and PRD 0026.
//

import SwiftUI

struct CreateBookPublishFooter: View {
    let failure: CreateBookFailure?
    let isPublishable: Bool
    let onPublish: () async -> Void

    /// Closes the whole sheet, not the screen this footer sits on: the draft goes back to the
    /// session, and the same barcode reopens on it.
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: .small) {
            AsyncButton(
                action: onPublish,
                actionOptions: [.showProgressView],
                label: {
                    Text(failure?.isWorthRetrying == true ? "create_book.retry" : "create_book.publish")
                        .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.primary())
            .disabled(isPublishable == false)
            .accessibilityIdentifier("e2e.createBook.publish")

            // Only once something has failed: before that, closing is closing, and a second way
            // out would be one too many.
            if failure != nil {
                Button("create_book.keep_draft", action: onClose)
                    .buttonStyle(.secondary())
                    .accessibilityIdentifier("e2e.createBook.keepDraft")
            }
        }
    }
}
