//
//  EditEditionFlowView.swift
//  ReCIT_iOS
//
//  The sheet the book screen's « Modifier » opens: what inventaire.io holds about the edition,
//  read fresh, then the form, and « Image depuis une URL » pushed over it.
//
//  A sheet with its own navigation stack rather than a screen pushed onto the book's: the book
//  screen's stack belongs to its tab, and the form, like the creation's, has a screen of its own
//  to push and a « ? » that opens the help in a sheet of its own.
//
//  The local edition is read for its uri only. What the form starts from comes from the server,
//  because each change has to name the value it replaces (`EditionClaims`). Saving writes the
//  claims that landed back into the local edition — on a full success, and on a partial one too,
//  since what landed is what inventaire.io now shows.
//

import SwiftUI
import SwiftData

struct EditEditionFlowView: View {
    @Environment(EntityCreationModel.self) private var creationModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let edition: Edition

    private enum Phase: Equatable {
        case loading
        case failed
        case loaded
    }

    @State private var phase: Phase = .loading
    @State private var edit: EditionEdit?
    @State private var path: [EditEditionStep] = []

    /// What went wrong at the last save, in the reader's terms. `nil` until something does.
    @State private var failure: CreateBookFailure?

    /// Whether the help about bibliographic data is up, asked for by the « ? » or by the
    /// notice's « En savoir plus ».
    @State private var isShowingHelp: Bool = false

    /// Bumped by « Réessayer » when the edition could not be read: the `.task` key.
    @State private var attempt: Int = 0

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch phase {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    BookAbsenceView(absence: .failed) { attempt += 1 }
                case .loaded:
                    if let binding = Binding($edit) {
                        EditEditionView(
                            edit: binding,
                            failure: failure,
                            onSave: save,
                            onPickCoverURL: { path.append(.coverFromURL) }
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "edit_edition.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                    .accessibilityIdentifier("e2e.editEdition.close")
                }
            }
            .navigationDestination(for: EditEditionStep.self) { step in
                switch step {
                case .coverFromURL:
                    CoverURLView(
                        // The work's title first, which is what a cover is known by.
                        searchedTitle: edition.works.first?.title ?? edit?.trimmedTitle ?? edition.title,
                        isbn: edit?.original.normalizedISBN ?? ""
                    ) { jpeg, _ in
                        // `update-claim` takes a hash: the bytes are uploaded, the address is not
                        // sent anywhere.
                        edit?.coverData = jpeg
                    }
                }
            }
        }
        .environment(\.showBibliographicDataHelp, .init { isShowingHelp = true })
        .sheet(isPresented: $isShowingHelp) {
            BibliographicDataHelpView()
        }
        .task(id: attempt) {
            await load()
        }
    }

    /// Reads the edition's claims, then its cover, so the frame shows the picture it has.
    ///
    /// The cover is a nicety: when it does not download, the form opens with an empty frame,
    /// and a picture added there replaces the one the edition has.
    private func load() async {
        phase = .loading

        do {
            let claims: EditionClaims = try await creationModel.editableEdition(uri: edition.uri)
            var loaded: EditionEdit = .init(original: claims)

            if let hash = claims.coverHash,
               let url = creationModel.coverURL(hash: hash),
               case .loaded(let jpeg, _, _) = await CoverURLPreview.load(url) {
                loaded.originalCoverData = jpeg
            }

            edit = loaded
            phase = .loaded
        } catch {
            phase = .failed
        }
    }

    /// Sends what changed, then shows it on the book screen.
    ///
    /// A failure leaves the form as it is, with everything typed still there, and the claims
    /// that did land already moved out of what the next try sends.
    private func save() async {
        guard let current = edit else { return }
        failure = nil

        do {
            let saved: EditionEdit = try await creationModel.saveEdition(current)
            creationModel.apply(
                saved.original,
                since: current.original,
                to: edition,
                modelContext: modelContext
            )
            edit = saved
            dismiss()
        } catch let saveFailure as EditionSaveFailure {
            creationModel.apply(
                saveFailure.edit.original,
                since: current.original,
                to: edition,
                modelContext: modelContext
            )
            edit = saveFailure.edit
            failure = .init(error: saveFailure.underlying)
            Haptics.Notification.error.play()
        } catch {
            failure = .init(error: error)
            Haptics.Notification.error.play()
        }
    }
}
