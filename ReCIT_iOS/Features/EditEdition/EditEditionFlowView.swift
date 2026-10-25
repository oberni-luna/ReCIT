//
//  EditEditionFlowView.swift
//  ReCIT_iOS
//
//  The sheet the book screen's « Données bibliographiques » opens: what inventaire.io holds about
//  the edition and its works, read fresh, then the form, and what it pushes over itself — the
//  search for a work (`V2 · Quelle œuvre ?` of « Nouveau livre v2 »), « Modifier l'œuvre » and
//  its author search, « Image depuis une URL », and the screens of the catalogue's properties.
//
//  A sheet with its own navigation stack rather than a screen pushed onto the book's: the book
//  screen's stack belongs to its tab, and the form, like the creation's, has screens of its own
//  to push and a « ? » that opens the help in a sheet of its own.
//
//  The local edition is read for its uri only. What the form starts from comes from the server,
//  because each change has to name the value it replaces (`EditionClaims`). Saving writes what
//  landed back into the local edition — on a full success, and on a partial one too, since what
//  landed is what inventaire.io now shows — and reads the works again when they moved or
//  changed, so the book screen names who wrote them.
//

import SwiftUI
import SwiftData

struct EditEditionFlowView: View {
    @Environment(EntityCreationModel.self) private var creationModel
    @Environment(EntityModel.self) private var entityModel
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
                            onAddWork: { path.append(.work) },
                            onOpenWork: { path.append(.workDetail(id: $0)) },
                            onPickCoverURL: { path.append(.coverFromURL) },
                            onOpenProperty: open,
                            onAddIdentifier: { path.append(.identifierCatalog($0)) }
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
                case .work:
                    WorkSearchView(
                        isbn: edit?.original.isbn ?? "",
                        onChoose: { candidate in
                            edit?.addWork(candidate)
                            path.removeLast()
                        },
                        onCreate: { query in
                            // The new work's own screen in place of the search: it needs an
                            // author before it can be saved.
                            path.removeLast()
                            if let id = edit?.startNewWork(titled: query) {
                                path.append(.workDetail(id: id))
                            }
                        },
                        emptyTitle: "edit_edition.work.search_empty.title",
                        emptyMessage: "edit_edition.work.search_empty.message"
                    )
                    .navigationTitle(String(localized: "edit_edition.works.add"))
                    .navigationBarTitleDisplayMode(.inline)
                case .workDetail(let id):
                    if let work = work(id) {
                        EditWorkView(work: work) {
                            path.append(.workAuthor(id: id))
                        }
                    }
                case .workAuthor(let id):
                    // Pops itself once an author is picked or created.
                    AuthorPickerView(initialQuery: "") { author in
                        guard let index = edit?.works.firstIndex(where: { $0.id == id }) else { return }
                        edit?.works[index].addAuthor(author)
                    }
                case .coverFromURL:
                    CoverURLView(
                        // The work's title first, which is what a cover is known by.
                        searchedTitle: edit?.works.first?.trimmedTitle ?? edit?.trimmedTitle ?? edition.title,
                        isbn: edit?.original.normalizedISBN ?? ""
                    ) { jpeg, _ in
                        // `update-claim` takes a hash: the bytes are uploaded, the address is not
                        // sent anywhere.
                        edit?.coverData = jpeg
                    }
                case .values(let uri):
                    if let property = EditionProperty.named(uri) {
                        EditionEntityValuesView(property: property, properties: properties) {
                            path.append(.picker(property: uri))
                        }
                    }
                case .picker(let uri):
                    if let property = EditionProperty.named(uri) {
                        // Pops itself once an entity is picked or created.
                        EntityPickerView(
                            property: property,
                            hasPublisher: edit?.properties.entities(of: .publisher).isEmpty == false
                        ) { entity in
                            edit?.properties.add(entity, to: property)
                        }
                    }
                case .publicationDate:
                    PublicationDateView(properties: properties)
                case .identifierCatalog(let group):
                    IdentifierCatalogView(group: group) { property in
                        path.append(.identifierInput(property: property.uri))
                    }
                case .identifierInput(let uri):
                    if let property = EditionProperty.named(uri) {
                        IdentifierInputView(property: property) { literal in
                            edit?.properties.addLiteral(literal, to: property)
                            // Back past the catalogue, to the form.
                            path.removeLast(min(2, path.count))
                        }
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

    /// One work of the form, for « Modifier l'œuvre ». `nil` once it has been detached.
    private func work(_ id: UUID) -> Binding<WorkEdit>? {
        guard let current = edit?.works.first(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { edit?.works.first(where: { $0.id == id }) ?? current },
            set: { newValue in
                guard let index = edit?.works.firstIndex(where: { $0.id == id }) else { return }
                edit?.works[index] = newValue
            }
        )
    }

    /// The form's properties, for the screens pushed over it.
    private var properties: Binding<EditionProperties> {
        Binding(
            get: { edit?.properties ?? .init() },
            set: { edit?.properties = $0 }
        )
    }

    /// Pushes what changes `property`: the date's screen, or — for an entity — the list of its
    /// values, or the search straight away when there are none.
    private func open(_ property: EditionProperty) {
        if property == .publicationDate {
            path.append(.publicationDate)
        } else if edit?.properties.entities(of: property).isEmpty == false {
            path.append(.values(property: property.uri))
        } else {
            path.append(.picker(property: property.uri))
        }
    }

    /// Reads the edition's claims, then its works and its cover.
    ///
    /// The works are part of what the form needs: their titles and authors are what « Modifier
    /// l'œuvre » starts from and compares against. The cover is a nicety: when it does not
    /// download, the form opens with an empty frame, and a picture added there replaces the one
    /// the edition has.
    private func load() async {
        phase = .loading

        do {
            let claims: EditionClaims = try await creationModel.editableEdition(uri: edition.uri)

            // The edition's cover stands for its works' in their rows.
            let works: [EditionWork] = try await creationModel.describeWorks(uris: claims.workUris).map { work in
                var work: EditionWork = work
                work.imageUrl = work.imageUrl ?? edition.image
                return work
            }

            var loaded: EditionEdit = .init(original: claims, originalWorks: works)

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
    /// A failure leaves the form as it is, with everything typed still there, and what did land
    /// already moved out of what the next try sends.
    private func save() async {
        guard let current = edit else { return }
        failure = nil

        do {
            let saved: EditionEdit = try await creationModel.saveEdition(current)
            await show(saved, since: current)
            edit = saved
            dismiss()
        } catch let saveFailure as EditionSaveFailure {
            await show(saveFailure.edit, since: current)
            edit = saveFailure.edit
            failure = .init(error: saveFailure.underlying)
            Haptics.Notification.error.play()
        } catch {
            failure = .init(error: error)
            Haptics.Notification.error.play()
        }
    }

    /// Writes into the store what landed between `before` and `after`: the edition's own claims
    /// directly, its works by reading them again — the works an edition points at, and the
    /// authors they name, live in other entities than the one the form changed.
    private func show(
        _ after: EditionEdit,
        since before: EditionEdit
    ) async {
        creationModel.apply(
            after.original,
            since: before.original,
            to: edition,
            modelContext: modelContext
        )

        let worksMoved: Bool = Set(after.original.workUris) != Set(before.original.workUris)
        let worksChanged: Bool = worksMoved || before.works.contains(where: \.hasChanges)
        guard worksChanged else { return }

        var works: [Work] = []
        for uri in after.original.workUris {
            if let work = try? await entityModel.refreshWork(modelContext: modelContext, uri: uri) {
                works.append(work)
            }
        }

        guard worksMoved, edition.isStillInTheStore else { return }
        edition.works = works
        try? modelContext.save()
    }
}
