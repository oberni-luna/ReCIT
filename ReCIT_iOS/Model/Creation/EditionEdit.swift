//
//  EditionEdit.swift
//  ReCIT_iOS
//
//  What the reader has changed in « Modifier l'édition », and what that comes to on the wire. A
//  value type with no opinion about the network: the form fills it, `EntityCreationModel` runs
//  the steps it lists, and tells it which ones landed.
//
//  Besides the edition's own title, subtitle and cover, the form changes the works the edition
//  is an edition of — added from the search or created, detached with a swipe — each work's
//  title and authors (`WorkEdit`), and every other property of the catalogue
//  (`EditionProperties`). Whatever has to exist before a claim can name it goes first: the
//  picture, the authors inventaire.io does not have, the works being created, the publishers,
//  collections and people the edition names. Then the claims, one at a time, then the works'
//  new titles.
//
//  **A change half sent is finished, not redone.** Each step is its own request, so a title can
//  land and a cover fail. Each one landed moves into `original`, a work's `original` or an
//  author's `uri`, and the retry lists only what is left — creating an author twice would put a
//  twin on a public database, and sending the title again would name, as the value it
//  replaces, a title the edition no longer has.
//

import Foundation

struct EditionEdit: Equatable, Sendable {

    /// What became of the cover since the form opened.
    enum Cover: Equatable, Sendable {
        case unchanged
        /// A new picture, as JPEG bytes, not yet hung on the edition.
        case replaced(Data)
        /// The edition's picture taken away.
        case removed
    }

    /// The edition as the server holds it — when the form opened, then after each change that
    /// landed.
    private(set) var original: EditionClaims

    var title: String
    var subtitle: String
    private(set) var cover: Cover = .unchanged

    /// The picture the edition had when the form opened, downloaded to fill the cover frame.
    /// `nil` when it has none, and when the download failed — the frame then offers to add one,
    /// which replaces it.
    var originalCoverData: Data?

    /// The hash a replacing picture was filed under, once uploaded: a retry hangs it on the
    /// edition without sending the same picture twice.
    var uploadedCoverHash: String?

    /// The works the form lists under « Édition de », in order.
    var works: [WorkEdit]

    /// The publisher, date, format, contributors, identifiers and links, as the form has them.
    var properties: EditionProperties

    init(
        original: EditionClaims,
        originalWorks: [EditionWork] = [],
        originalCoverData: Data? = nil
    ) {
        self.original = original
        self.originalCoverData = originalCoverData
        title = original.title
        subtitle = original.subtitle ?? ""
        // Every work the edition names is listed, described or not: one the description left
        // out would otherwise read as detached, and be unclaimed on the next save.
        works = original.workUris.map { uri in
            WorkEdit(original: originalWorks.first { $0.uri == uri } ?? .init(uri: uri, title: uri))
        }
        properties = original.properties
    }

    // MARK: - The cover

    /// The picture the cover frame shows, and the binding it writes through: a picture set
    /// replaces the edition's, none removes it.
    var coverData: Data? {
        get {
            switch cover {
            case .unchanged: originalCoverData
            case .replaced(let data): data
            case .removed: nil
            }
        }
        set {
            uploadedCoverHash = nil
            if let newValue {
                cover = .replaced(newValue)
            } else {
                // Taking away a picture the edition never had changes nothing.
                cover = original.coverHash == nil ? .unchanged : .removed
            }
        }
    }

    /// The picture to upload before the cover's claim can be sent: a replacing one whose hash
    /// is not known yet.
    var coverToUpload: Data? {
        guard case .replaced(let data) = cover, uploadedCoverHash == nil else { return nil }
        return data
    }

    // MARK: - The works

    /// Adds a work picked from the search — unless the edition lists it already.
    mutating func addWork(_ candidate: WorkCandidate) {
        guard works.contains(where: { $0.uri == candidate.uri }) == false else { return }
        works.append(.init(original: .init(candidate: candidate)))
    }

    /// None of the works found is the book's: one is created, named after the search. Answers
    /// its id, for the screen that gives it authors.
    @discardableResult
    mutating func startNewWork(titled query: String) -> UUID {
        let work: WorkEdit = .init(newTitled: query)
        works.append(work)
        return work.id
    }

    /// What a swipe on « Détacher » takes away: the edition stops being an edition of the work.
    /// The work itself stays on inventaire.io.
    mutating func detachWork(id: UUID) {
        works.removeAll { $0.id == id }
    }

    /// Shows a work as « Modifier l'œuvre » just saved it, in place of the row that opened it.
    /// The work's picture is the edition's: the row keeps the one it had.
    mutating func workSaved(_ work: EditionWork) {
        guard let index = works.firstIndex(where: { $0.uri == work.uri }) else { return }
        var saved: EditionWork = work
        saved.imageUrl = works[index].imageUrl
        works[index] = .init(original: saved, id: works[index].id)
    }

    /// Shows a person under the name « Modifier l'auteur·ice » just saved: among the works'
    /// authors and among the people the edition names.
    mutating func rename(uri: String, label: String) {
        for index in works.indices {
            works[index].renameAuthor(uri: uri, name: label)
        }
        properties.rename(uri: uri, label: label)
        original.properties.rename(uri: uri, label: label)
    }

    /// The uris of the works listed that exist.
    var workUris: [String] {
        works.compactMap(\.uri)
    }

    // MARK: - What there is to send

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitle: String {
        subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var originalTitle: String {
        original.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var originalSubtitle: String {
        (original.subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasChanges: Bool {
        trimmedTitle != originalTitle
            || trimmedSubtitle != originalSubtitle
            || cover != .unchanged
            || Set(workUris) != Set(original.workUris)
            || works.contains(where: \.hasChanges)
            || properties.differs(from: original.properties)
    }

    /// Whether there is something to send, and it can be sent. An edition without a title is
    /// unreadable in every list it appears in, and one with no work is refused by inventaire.io
    /// (`wdt:P629` is required); a work created without a title or an author is the kind of
    /// orphan that has to be repaired by hand on the website afterwards.
    var isSaveable: Bool {
        guard trimmedTitle.isEmpty == false, hasChanges,
              works.isEmpty == false, works.allSatisfy(\.isComplete) else { return false }

        // A collection is created under its publisher: one with no publisher to be created
        // under would stay unsent.
        let collectionsToCreate: Bool = properties.pendingEntities.contains { $0.property == .collection }
        return collectionsToCreate == false || properties.entities(of: .publisher).isEmpty == false
    }

    /// The language the labels of a created author or work are written in: the edition's own,
    /// or the reader's when the edition does not say.
    var labelLanguage: String {
        original.labelLanguage ?? ResolveRequestBuilder.defaultLabelLanguage
    }

    /// The next request of the save, or `nil` once everything has landed.
    var nextStep: EditionEditStep? {
        if let data = coverToUpload {
            return .uploadCover(data)
        }
        for work in works where work.isEditable {
            if let author = work.authors.first(where: { $0.uri == nil }) {
                return .createAuthor(id: author.id, label: author.trimmedName, language: labelLanguage)
            }
        }
        if let work = works.first(where: \.isNew) {
            return .createWork(
                id: work.id,
                label: work.trimmedTitle,
                language: labelLanguage,
                authorUris: work.authors.compactMap(\.uri)
            )
        }
        for pending in properties.pendingEntities {
            guard let kind = EntityCreationKind(for: pending.property, publisherUri: properties.publisherUri) else { continue }
            return .createEntity(id: pending.entity.id, label: pending.entity.trimmedLabel, language: labelLanguage, kind: kind)
        }
        if let update = claimUpdates.first {
            return .claim(update)
        }
        return labelUpdates.first.map { .label($0) }
    }

    /// The claims to send, in order: the edition's title, subtitle, cover and works, its other
    /// properties, then the authors added to and taken from its works. A replacing cover is
    /// listed once its hash is known, an author or a work once it exists.
    var claimUpdates: [EditionClaimUpdate] {
        var updates: [EditionClaimUpdate] = []

        if trimmedTitle != originalTitle {
            updates.append(update(.title, from: original.title, to: trimmedTitle))
        }

        if trimmedSubtitle != originalSubtitle {
            updates.append(update(.subtitle, from: original.subtitle, to: trimmedSubtitle))
        }

        switch cover {
        case .replaced:
            if let uploadedCoverHash {
                updates.append(update(.cover, from: original.coverHash, to: uploadedCoverHash))
            }
        case .removed:
            updates.append(update(.cover, from: original.coverHash, to: nil))
        case .unchanged:
            break
        }

        let current: [String] = workUris
        for detached in original.workUris where current.contains(detached) == false {
            updates.append(update(.work, from: detached, to: nil))
        }
        for added in current where original.workUris.contains(added) == false {
            updates.append(update(.work, from: nil, to: added))
        }

        updates += properties.updates(since: original.properties, on: original.uri)

        for work in works where work.isEditable {
            guard let uri = work.uri else { continue }
            for case let author? in work.addedAuthors.map(\.uri) {
                updates.append(update(.author, of: uri, from: nil, to: author))
            }
            for case let author? in work.removedAuthors.map(\.uri) {
                updates.append(update(.author, of: uri, from: author, to: nil))
            }
        }

        return updates
    }

    /// The works renamed, as `update-label` takes them: in the language of the title they had.
    var labelUpdates: [EntityLabelUpdate] {
        works.compactMap { work in
            guard let uri = work.uri, let title = work.renamedTitle else { return nil }
            return .init(uri: uri, lang: work.original?.titleLanguage ?? labelLanguage, value: title)
        }
    }

    // MARK: - What landed

    /// Records the hash a new cover was filed under.
    mutating func coverUploaded(hash: String) {
        uploadedCoverHash = hash
    }

    /// Records the uri an author was created under: it is named from now on.
    mutating func authorCreated(id: UUID, uri: String) {
        for index in works.indices {
            if works[index].authorCreated(id: id, uri: uri) { return }
        }
    }

    /// Records a work created: it exists now, written by its authors, and only the edition's
    /// claim on it is left to send.
    mutating func workCreated(id: UUID, uri: String) {
        guard let index = works.firstIndex(where: { $0.id == id }) else { return }
        works[index].created(uri: uri, titleLanguage: labelLanguage)
    }

    /// Records the uri a publisher, a collection or a person was created under.
    mutating func entityCreated(id: UUID, uri: String) {
        properties.entityCreated(id: id, uri: uri)
    }

    /// Records that `update` landed: what it changed now holds its new value, so it drops out of
    /// `claimUpdates`.
    mutating func landed(_ update: EditionClaimUpdate) {
        let oldValue: String? = update.oldValue?.string
        let newValue: String? = update.newValue?.string

        switch EditableClaimProperty(rawValue: update.property) {
        case .title:
            original.title = newValue ?? ""
        case .subtitle:
            original.subtitle = newValue
        case .cover:
            original.coverHash = newValue
            originalCoverData = coverData
            cover = .unchanged
            uploadedCoverHash = nil
        case .work:
            if let oldValue { original.workUris.removeAll { $0 == oldValue } }
            if let newValue { original.workUris.append(newValue) }
        case .author:
            guard let index = works.firstIndex(where: { $0.uri == update.uri }) else { return }
            works[index].authorLanded(added: newValue, removed: oldValue)
        case nil:
            original.properties.apply(update, from: properties)
        }
    }

    /// Records that a work's new title landed.
    mutating func landed(_ update: EntityLabelUpdate) {
        guard let index = works.firstIndex(where: { $0.uri == update.uri }) else { return }
        works[index].titleLanded(update.value)
    }

    /// An update naming the value it replaces, on the edition unless said otherwise. An empty
    /// value on either side is no value: no old one adds the claim, no new one removes it.
    private func update(
        _ property: EditableClaimProperty,
        of uri: String? = nil,
        from oldValue: String?,
        to newValue: String?
    ) -> EditionClaimUpdate {
        .init(
            uri: uri ?? original.uri,
            property: property,
            oldValue: oldValue?.isEmpty == true ? nil : oldValue,
            newValue: newValue?.isEmpty == true ? nil : newValue
        )
    }
}
