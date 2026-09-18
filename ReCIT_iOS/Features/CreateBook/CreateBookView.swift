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

    /// The work inventaire.io recognised, once the reconnaissance pass has found one. Pushing
    /// on it rather than publishing straight away is the whole of issue 0094.
    @State private var recognisedWorkUri: String?

    /// Whether the camera is up. The cover is the one thing in this form that is taken rather
    /// than typed.
    @State private var isCapturingCover: Bool = false

    init(isbn: String, onCreated: @escaping (ScannedBook) -> Void) {
        self.isbn = isbn
        self.onCreated = onCreated
        _draft = State(initialValue: .init(isbn: isbn))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .top, spacing: .medium) {
                        Button {
                            isCapturingCover = true
                        } label: {
                            CreateBookCoverSlot(imageData: draft.coverImageData)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("e2e.createBook.cover")

                        Text(isbn)
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                            .accessibilityIdentifier("e2e.createBook.isbn")
                            .withLabel(label: "create_book.isbn")
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        // Only when the ISBN has answered. Saying nothing is the honest state
                        // when the group has no language or the call did not come back.
                        if let language = draft.language?.localizedName {
                            Text("create_book.language \(language)")
                                .textStyle(.footnote200)
                                .foregroundStyle(.foregroundSecondary)
                                .accessibilityIdentifier("e2e.createBook.language")
                        }

                        Text("create_book.public_notice")
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundSecondary)
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {
                    TextField("create_book.title_field", text: $draft.title)
                        .accessibilityIdentifier("e2e.createBook.title")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "create_book.title_field")

                    NavigationLink {
                        AuthorPickerView(draft: $draft)
                    } label: {
                        CreateBookAuthorRow(draft: draft)
                    }
                    .accessibilityIdentifier("e2e.createBook.author")
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
            .fullScreenCover(isPresented: $isCapturingCover) {
                CoverCaptureView { data in
                    draft.coverImageData = data
                    // A new photograph invalidates the one already uploaded, if the reader is
                    // retrying after a failure: the next publication sends this one.
                    draft.coverImageUrl = nil
                }
                .ignoresSafeArea()
            }
            .navigationDestination(item: $recognisedWorkUri) { uri in
                WorkMatchView(workUri: uri, draft: $draft, onPublish: create)
            }
            .task {
                // Asked once, as the form opens, and never blocking: the reader can type the
                // whole book before the answer lands, and publish whether or not it does.
                draft.language = await creationModel.editionLanguage(isbn: isbn)
            }
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

    /// What the publish button does: ask before writing.
    ///
    /// The reconnaissance pass writes nothing and can recognise a work this book is an edition
    /// of — in which case the reader is shown it and decides, and the publication happens from
    /// that screen. Asked at most once: a reader who answered « no, it is another book » is not
    /// asked again on a retry.
    private func publish() async {
        if draft.hasAnsweredWorkQuestion == false,
           let uri = await creationModel.recogniseWork(draft: draft) {
            recognisedWorkUri = uri
            return
        }

        await create()
    }

    /// Creates the book on inventaire.io, then files it — in that order, because the second
    /// needs the canonical uri the first answers with.
    ///
    /// A failure leaves the sheet exactly as it is, with everything typed still there: nothing
    /// was created on the server, so trying again makes no duplicate. Issue 0096 gives that
    /// failure a proper face; until then it is said on the shared snack bar.
    private func create() async {
        guard let user = userModel.myUser else { return }

        // Before the publication, because the url goes in the same request — and never in its
        // way: an upload that does not land costs a picture, not a book. `enrich` covers the
        // books nobody photographed anyway.
        if let imageData = draft.coverImageData, draft.coverImageUrl == nil {
            draft.coverImageUrl = await creationModel.uploadCover(imageData: imageData)
        }

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

/// The author line of the form: who has been chosen, or an invitation to choose.
///
/// A row rather than a text field, since issue 0093. Typing a name straight in is what makes a
/// second « Ursula K. Le Guin »; going through a screen that shows the existing ones first is
/// what does not.
private struct CreateBookAuthorRow: View {
    let draft: NewBookDraft

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text("create_book.author_field")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)

            if draft.trimmedAuthorName.isEmpty {
                Text("create_book.author.choose")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundPlaceholder)
            } else {
                Text(draft.trimmedAuthorName)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                if let description = draft.authorDescription, description.isEmpty == false {
                    Text(description)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The cover slot: a photograph taken, or a dashed frame inviting one.
///
/// Facultative, and drawn so: a dashed outline rather than a filled control, because the book
/// is published with or without it. What it is for is written under it, since a camera glyph
/// alone in a form about a book could as easily mean the barcode.
private struct CreateBookCoverSlot: View {
    let imageData: Data?

    var body: some View {
        slot
            .frame(width: 88, height: 132)
            .background(.backgroundSecondary)
            .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay {
                if imageData == nil {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(
                            DesignSystem.Color.borderDefault.color,
                            style: .init(lineWidth: 1, dash: [4, 4])
                        )
                }
            }
            .accessibilityLabel(Text("create_book.cover.take"))
    }

    @ViewBuilder
    private var slot: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            VStack(spacing: .small) {
                Image(systemName: "camera")
                    .foregroundStyle(.foregroundTinted)

                Text("create_book.cover.take")
                    .textStyle(.caption200)
                    .foregroundStyle(.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.all, .small)
        }
    }
}
