//
//  EditEditionFlowView.swift
//  ReCIT_iOS
//
//  The sheet the book screen's « Données bibliographiques » opens: what inventaire.io holds about
//  the edition and its works, read fresh, then the form, and what it pushes over itself — the
//  search for a work (`V2 · Quelle œuvre ?` of « Nouveau livre v2 »), « Modifier l'œuvre » and
//  its author search, « Image depuis une URL », and the screens of the catalogue's properties.
//
//  A work inventaire.io has opens the whole of « Modifier l'œuvre » (`EditEntityView`), saved by
//  its own « Enregistrer », and so does a person — « Modifier l'auteur·ice » — touched among a
//  work's authors or in the list of a role; a work being created, or a Wikidata one, keeps the title and authors
//  of `EditWorkView`, saved with the edition. The entities those screens change are held here,
//  keyed by uri, for as long as their screen is on the stack.
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

    /// The works and people pushed over the form, as their screens change them.
    @State private var entities: [String: EntityEdit] = [:]
    /// What went wrong at the last save of each of them.
    @State private var entityFailures: [String: CreateBookFailure] = [:]

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
                            onOpenWork: openWork,
                            onPickCoverURL: { path.append(.coverFromURL) },
                            onOpenProperty: open,
                            onAddIdentifier: { path.append(.property(.identifierCatalog($0))) }
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
                case .property(let step):
                    EditionPropertyDestination(
                        step: step,
                        properties: properties,
                        push: { path.append(.property($0)) },
                        pop: { path.removeLast(min($0, path.count)) },
                        openEntity: { path.append(.entity(uri: $0)) }
                    )
                case .entity(let uri):
                    EditEntityView(
                        uri: uri,
                        edit: entity(uri),
                        failure: entityFailures[uri],
                        onSave: { await saveEntity(uri) },
                        onLeave: { popEntity(uri) },
                        onOpenProperty: { property in
                            path.append(.entityProperty(uri: uri, step: .opening(property, in: entities[uri]?.properties ?? .init())))
                        },
                        onPick: { path.append(.entityProperty(uri: uri, step: .picker(property: $0.uri))) },
                        onAddIdentifier: { path.append(.entityProperty(uri: uri, step: .identifierCatalog($0))) },
                        onOpenEntity: { path.append(.entity(uri: $0)) }
                    )
                case .entityProperty(let uri, let step):
                    EditionPropertyDestination(
                        step: step,
                        properties: entityProperties(uri),
                        push: { path.append(.entityProperty(uri: uri, step: $0)) },
                        pop: { path.removeLast(min($0, path.count)) },
                        openEntity: { path.append(.entity(uri: $0)) }
                    )
                }
            }
        }
        .onChange(of: path) { _, newPath in
            forgetEntities(notIn: newPath)
        }
        .environment(\.showBibliographicDataHelp, .init { isShowingHelp = true })
        .sheet(isPresented: $isShowingHelp) {
            BibliographicDataHelpView()
        }
        .task(id: attempt) {
            await load()
        }
    }

    /// Pushes the screen of a work of « Édition de »: the whole of « Modifier l'œuvre » for one
    /// inventaire.io has, the title and authors of `EditWorkView` for one being created or one
    /// of Wikidata's.
    private func openWork(_ id: UUID) {
        guard let work = edit?.works.first(where: { $0.id == id }),
              work.isNew == false, work.isEditable, let uri = work.uri else {
            path.append(.workDetail(id: id))
            return
        }
        path.append(.entity(uri: uri))
    }

    /// The work or person with this uri, as its screen changes it. `nil` until it is read.
    private func entity(_ uri: String) -> Binding<EntityEdit?> {
        Binding(
            get: { entities[uri] },
            set: { entities[uri] = $0 }
        )
    }

    /// Its properties, for the screens pushed over it.
    private func entityProperties(_ uri: String) -> Binding<EditionProperties> {
        Binding(
            get: { entities[uri]?.properties ?? .init() },
            set: { entities[uri]?.properties = $0 }
        )
    }

    /// Drops what the screens no longer on the stack were changing: going back to one reads it
    /// afresh.
    private func forgetEntities(notIn path: [EditEditionStep]) {
        let shown: Set<String> = Set(path.compactMap { step in
            guard case .entity(let uri) = step else { return nil }
            return uri
        })
        for uri in entities.keys where shown.contains(uri) == false {
            entities[uri] = nil
            entityFailures[uri] = nil
        }
    }

    /// Takes the entity's screen off the stack, with whatever it had pushed — after a save, or
    /// dropping what was not saved.
    private func popEntity(_ uri: String) {
        guard let index = path.lastIndex(of: .entity(uri: uri)) else { return }
        path.removeSubrange(index...)
    }

    /// Sends what the work's or the person's screen changed, shows it beneath, then goes back.
    ///
    /// A failure leaves the screen as it is, everything typed still there, and what did land
    /// already moved out of what the next try sends.
    private func saveEntity(_ uri: String) async {
        guard let current = entities[uri] else { return }
        entityFailures[uri] = nil

        do {
            let saved: EntityEdit = try await creationModel.saveEntity(current)
            entities[uri] = saved
            await show(saved)
            popEntity(uri)
        } catch let saveFailure as EntitySaveFailure {
            entities[uri] = saveFailure.edit
            entityFailures[uri] = .init(error: saveFailure.underlying)
            Haptics.Notification.error.play()
        } catch {
            entityFailures[uri] = .init(error: error)
            Haptics.Notification.error.play()
        }
    }

    /// Shows a saved work or person on the screens beneath it, and in the store: a work's row in
    /// « Édition de », a person's name wherever it is named.
    private func show(_ saved: EntityEdit) async {
        switch saved.catalogue {
        case .work:
            edit?.workSaved(saved.editionWork)
            _ = try? await entityModel.refreshWork(modelContext: modelContext, uri: saved.uri)
        case .human:
            edit?.rename(uri: saved.uri, label: saved.displayName)
            for uri in entities.keys where uri != saved.uri {
                entities[uri]?.rename(uri: saved.uri, label: saved.displayName)
            }
            _ = try? await entityModel.refreshAuthor(modelContext: modelContext, uri: saved.uri)
        case .edition:
            break
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

    /// Pushes what changes `property`.
    private func open(_ property: EditionProperty) {
        path.append(.property(.opening(property, in: edit?.properties ?? .init())))
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
