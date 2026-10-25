//
//  NewBookFlowView.swift
//  ReCIT_iOS
//
//  The sheet that turns a scan which found nothing into a contribution to inventaire.io: a
//  search for the work first, then the screens that describe what is missing. « Nouveau livre
//  v2 » (`712:21292`) in the Figma file; it replaces the single form of PRD 0015.
//
//  A `.sheet` posed on the camera rather than a screen pushed into the flow's navigation
//  stack: that stack belongs to the book screen, which a scanned row can already open, and the
//  two paths must not braid. While the sheet is up the scanner accepts no barcode — not by a
//  lock of its own, but because the machine is still holding `.notFound`.
//
//  The publication lives here, once, for the three screens that can trigger it. It waits for
//  the server, and the sheet stays open until it answers; `EntityCreationModel` says why at
//  length. A failure is said on the screen that published, beside the button that will try
//  again: the draft is still on it, and what the reader needs to know first — that nothing was
//  created, so trying again makes no twin — belongs there and not on the shared snack bar.
//
//  See PRD 0026.
//

import SwiftUI
import SwiftData

struct NewBookFlowView: View {
    @Environment(EntityCreationModel.self) private var creationModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Handed the book that now exists, so the row behind the sheet can confirm it and the
    /// session can count it. Called before the dismissal, and only on a full success.
    let onCreated: (ScannedBook) -> Void

    /// Handed what was typed, whatever takes the sheet away. A publication that failed must not
    /// cost the reader their typing: the session keeps the draft, and the same barcode reopens
    /// on it.
    let onKeepDraft: (NewBookDraft) -> Void

    @State private var draft: NewBookDraft
    @State private var path: [NewBookStep]

    /// What went wrong last time, in the reader's terms. `nil` until something does.
    @State private var failure: CreateBookFailure?

    /// Whether the help about bibliographic data is up, asked for by any screen's « ? » or by
    /// the notice's « En savoir plus ».
    @State private var isShowingHelp: Bool = false

    /// Whether the book now exists. Its draft is then done with, and must not be handed back to
    /// the session on the way out.
    @State private var isPublished: Bool = false

    init(
        draft: NewBookDraft,
        onCreated: @escaping (ScannedBook) -> Void,
        onKeepDraft: @escaping (NewBookDraft) -> Void
    ) {
        self.onCreated = onCreated
        self.onKeepDraft = onKeepDraft
        _draft = State(initialValue: draft)
        _path = State(initialValue: NewBookStep.resuming(draft))
    }

    var body: some View {
        NavigationStack(path: $path) {
            WorkSearchView(
                isbn: draft.isbn,
                onChoose: choose,
                onCreate: startNewWork
            )
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
            .navigationDestination(for: NewBookStep.self) { step in
                switch step {
                case .edition:
                    NewEditionView(
                        draft: $draft,
                        failure: failure,
                        onPublish: publish,
                        onClose: { dismiss() },
                        onPickCoverURL: pickCoverURL,
                        onFindWork: { path = [] },
                        onOpenNewWork: { path.append(.newWork) },
                        onOpenProperty: { path.append(.property(.opening($0, in: draft.properties))) },
                        onAddIdentifier: { path.append(.property(.identifierCatalog($0))) }
                    )
                case .newWork:
                    NewWorkView(draft: $draft)
                case .property(let step):
                    EditionPropertyDestination(
                        step: step,
                        properties: $draft.properties,
                        push: { path.append(.property($0)) },
                        pop: { path.removeLast(min($0, path.count)) }
                    )
                case .recognisedWork(let uri):
                    WorkMatchView(
                        workUri: uri,
                        draft: $draft,
                        failure: failure,
                        onPublish: create,
                        onClose: { dismiss() }
                    )
                case .coverFromURL:
                    CoverURLView(
                        searchedTitle: draft.coverSearchTitle,
                        isbn: draft.normalizedISBN
                    ) { jpeg, url in
                        // The address is what `resolve` fetches; the bytes fill the frame.
                        draft.coverImageData = jpeg
                        draft.coverImageUrl = url.absoluteString
                    }
                }
            }
        }
        .environment(\.showBibliographicDataHelp, .init { isShowingHelp = true })
        .sheet(isPresented: $isShowingHelp) {
            BibliographicDataHelpView()
        }
        .task {
            // Asked once, as the sheet opens, and never blocking: the reader can describe the
            // whole book before the answer lands, and publish whether or not it does.
            draft.language = await creationModel.editionLanguage(isbn: draft.isbn)
        }
        .onDisappear {
            // Whatever took the sheet away — the close button, a swipe, a publication that
            // failed and a reader who walked off — what was typed stays with the session.
            guard isPublished == false else { return }
            onKeepDraft(draft)
        }
    }

    /// A work inventaire.io already has: only the edition is left to describe.
    private func choose(_ work: WorkCandidate) {
        draft.choose(work)
        failure = nil
        path = [.edition]
    }

    /// None of the works fits: the reader describes one, named after the search — on its own
    /// screen, over the edition's form, since it needs an author before anything is published.
    private func startNewWork(titled query: String) {
        draft.startNewWork(titled: query)
        failure = nil
        path = [.edition, .newWork]
    }

    /// A cover from the web, over whichever form asked for it.
    private func pickCoverURL() {
        path.append(.coverFromURL)
    }

    /// What « Publier » does: for a work being created, ask before writing.
    ///
    /// The reconnaissance pass writes nothing and can recognise a work this book is an edition
    /// of, which the search did not offer — in which case the reader is shown it and decides,
    /// and the publication happens from that screen. Asked at most once: a reader who answered
    /// « no, another work » is not asked again on a retry.
    private func publish() async {
        if draft.workUri == nil,
           draft.hasAnsweredWorkQuestion == false,
           let uri = await creationModel.recogniseWork(draft: draft) {
            path.append(.recognisedWork(uri: uri))
            return
        }

        await create()
    }

    /// Creates the book on inventaire.io, then files it — in that order, because the second
    /// needs the canonical uri the first answers with.
    ///
    /// A failure leaves the screen exactly as it is, with everything typed still there: nothing
    /// was created on the server, so trying again makes no duplicate.
    private func create() async {
        guard let user = userModel.myUser else { return }

        // Before the publication, because the url goes in the same request — and never in its
        // way: an upload that does not land costs a picture, not a book. `enrich` covers the
        // books nobody photographed anyway.
        if let imageData = draft.coverImageData, draft.coverImageUrl == nil {
            draft.coverImageUrl = await creationModel.uploadCover(imageData: imageData)
        }

        failure = nil

        do {
            // The publishers, collections and people nobody has entered yet exist before
            // `resolve` names them. Each one created is kept in the draft at once: a failure
            // further on does not create it twice.
            try await creationModel.createPendingEntities(
                of: draft.properties,
                language: draft.language?.code ?? ResolveRequestBuilder.defaultLabelLanguage
            ) { id, uri in
                draft.properties.entityCreated(id: id, uri: uri)
            }

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

            isPublished = true
            onCreated(
                .init(
                    uri: uri,
                    title: draft.trimmedTitle,
                    authors: draft.chosenWork?.authors ?? draft.namedAuthors.map(\.trimmedName),
                    coverImageUrl: nil,
                    code: draft.isbn
                )
            )
            dismiss()
        } catch {
            failure = .init(error: error)
            Haptics.Notification.error.play()
        }
    }
}
