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
//  barcode a moment ago, and the whole form exists because the *rest* is unknown. Two fields,
//  no more — see `NewBookDraft` for why those two.
//
//  Publishing waits for the server and the sheet stays open until it answers. Nothing about
//  this write is optimistic; `EntityCreationModel` says why at length.
//
//  See PRD 0015.
//

import SwiftUI
import SwiftData
import LBSnackBar

struct CreateBookView: View {
    @Environment(EntityCreationModel.self) private var creationModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar
    @Environment(\.dismiss) private var dismiss

    let isbn: String

    /// Handed the book that now exists, so the row behind the sheet can confirm it and the
    /// session can count it. Called before the dismissal, and only on a full success.
    let onCreated: (ScannedBook) -> Void

    @State private var draft: NewBookDraft

    init(isbn: String, onCreated: @escaping (ScannedBook) -> Void) {
        self.isbn = isbn
        self.onCreated = onCreated
        _draft = State(initialValue: .init(isbn: isbn))
    }

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

                Section {
                    TextField("create_book.title_field", text: $draft.title)
                        .accessibilityIdentifier("e2e.createBook.title")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "create_book.title_field")

                    TextField("create_book.author_field", text: $draft.authorName)
                        .accessibilityIdentifier("e2e.createBook.author")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "create_book.author_field")
                } footer: {
                    Text("create_book.title_help")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    AsyncButton(
                        action: publish,
                        actionOptions: [.showProgressView],
                        label: {
                            Text("create_book.publish")
                                .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.primary())
                    .disabled(draft.isPublishable == false)
                    .accessibilityIdentifier("e2e.createBook.publish")
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
    }

    /// Creates the book on inventaire.io, then files it — in that order, because the second
    /// needs the canonical uri the first answers with.
    ///
    /// A failure leaves the sheet exactly as it is, with everything typed still there: nothing
    /// was created on the server, so trying again makes no duplicate. Issue 0096 gives that
    /// failure a proper face; until then it is said on the shared snack bar.
    private func publish() async {
        guard let user = userModel.myUser else { return }

        do {
            let uri: String = try await creationModel.createEdition(draft: draft)

            // Same defaults as the scanner's own add, so a book that had to be created first is
            // indistinguishable afterwards from one that was already there.
            _ = try await inventoryModel.postNewItem(
                modelContext: modelContext,
                entityUri: uri,
                transaction: .inventorying,
                visibility: [.friends],
                forUser: user
            )

            onCreated(
                .init(
                    uri: uri,
                    title: draft.trimmedTitle,
                    authors: [draft.trimmedAuthorName],
                    coverImageUrl: nil,
                    code: isbn
                )
            )
            dismiss()
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}
