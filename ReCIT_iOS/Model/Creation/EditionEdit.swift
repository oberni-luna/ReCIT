//
//  EditionEdit.swift
//  ReCIT_iOS
//
//  What the reader has changed in « Modifier l'édition », and what that comes to on the wire. A
//  value type with no opinion about the network: the form fills it, `EntityCreationModel` runs
//  the steps it lists, and tells it which ones landed.
//
//  Besides the edition's own title, subtitle and cover, the form changes the work the edition is
//  an edition of — another one inventaire.io has, or one created from here — adds authors to
//  that work, and changes every other property of the catalogue (`EditionProperties`). Whatever
//  has to exist before a claim can name it goes first: the picture, the authors inventaire.io
//  does not have, the work being created, the publishers, collections and people the edition
//  names. Then the claims, one at a time.
//
//  **A change half sent is finished, not redone.** Each step is its own request, so a title can
//  land and a cover fail. Each one landed moves into `original`, `originalWork` or an author's
//  `uri`, and the retry lists only what is left — creating an author twice would put a twin on a
//  public database, and sending the title again would name, as the value it replaces, a title
//  the edition no longer has.
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

    /// What became of the work since the form opened.
    enum WorkChange: Equatable, Sendable {
        case unchanged
        /// Another work inventaire.io has: picked from the search, or just created.
        case existing(EditionWork)
        /// A work to create, titled `newWorkTitle`, written by the authors added.
        case new
    }

    /// The edition as the server holds it — when the form opened, then after each change that
    /// landed.
    private(set) var original: EditionClaims

    /// The work `original.workUri` names, described. `nil` for an edition attached to none.
    private(set) var originalWork: EditionWork?

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

    private(set) var workChange: WorkChange = .unchanged

    /// The title of the work being created.
    var newWorkTitle: String = ""

    /// The authors added to the work shown. One inventaire.io does not have gets its `uri` once
    /// created, so a retry does not create it twice.
    private(set) var addedAuthors: [NewBookAuthor] = []

    /// The publisher, date, format, contributors, identifiers and links, as the form has them.
    var properties: EditionProperties

    init(
        original: EditionClaims,
        originalWork: EditionWork? = nil,
        originalCoverData: Data? = nil
    ) {
        self.original = original
        self.originalWork = originalWork
        self.originalCoverData = originalCoverData
        title = original.title
        subtitle = original.subtitle ?? ""
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

    // MARK: - The work and its authors

    /// The work the form shows: the one chosen, or the edition's. `nil` for an edition attached
    /// to none, and while a work is being created.
    var work: EditionWork? {
        switch workChange {
        case .unchanged: originalWork
        case .existing(let work): work
        case .new: nil
        }
    }

    var isCreatingWork: Bool {
        workChange == .new
    }

    var trimmedNewWorkTitle: String {
        newWorkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether authors can be added to the work shown: one being created, or one of
    /// inventaire.io's own.
    var canAddAuthors: Bool {
        isCreatingWork || work?.isEditable == true
    }

    /// Makes the edition an edition of `candidate`. Picking the work it already has undoes the
    /// change rather than sending it.
    mutating func choose(_ candidate: WorkCandidate) {
        workChange = candidate.uri == originalWork?.uri ? .unchanged : .existing(.init(candidate: candidate))

        let authorsOnTheWork: [NewBookAuthor] = work?.authors ?? []
        addedAuthors.removeAll { added in
            authorsOnTheWork.contains { Self.isSamePerson($0, added) }
        }
    }

    /// None of the works found is the book's: one is created, named after the search.
    mutating func startNewWork(titled query: String) {
        workChange = .new
        newWorkTitle = NewBookDraft.capitalizingFirstLetter(query.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Adds an author to the work shown — unless they are on it already, or added already.
    mutating func addAuthor(_ author: NewBookAuthor) {
        guard author.trimmedName.isEmpty == false,
              isOnTheWork(author) == false,
              addedAuthors.contains(where: { Self.isSamePerson($0, author) }) == false else { return }

        addedAuthors.append(author)
    }

    /// What a swipe on the list of added authors takes away.
    mutating func removeAddedAuthors(atOffsets offsets: IndexSet) {
        for index in offsets.sorted(by: >) where addedAuthors.indices.contains(index) {
            addedAuthors.remove(at: index)
        }
    }

    private func isOnTheWork(_ author: NewBookAuthor) -> Bool {
        (work?.authors ?? []).contains { Self.isSamePerson($0, author) }
    }

    /// The same uri, or — when one side has none, as authors picked from the search do — the
    /// same name.
    private static func isSamePerson(_ lhs: NewBookAuthor, _ rhs: NewBookAuthor) -> Bool {
        if let left = lhs.uri, let right = rhs.uri { return left == right }
        return lhs.trimmedName.localizedCaseInsensitiveCompare(rhs.trimmedName) == .orderedSame
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
            || workChange != .unchanged
            || addedAuthors.isEmpty == false
            || properties.differs(from: original.properties)
    }

    /// Whether there is something to send, and it can be sent. An edition without a title is
    /// unreadable in every list it appears in, and a work created without a title or an author
    /// is the kind of orphan that has to be repaired by hand on the website afterwards.
    var isSaveable: Bool {
        guard trimmedTitle.isEmpty == false, hasChanges else { return false }

        // A collection is created under its publisher: one with no publisher to be created
        // under would stay unsent.
        let collectionsToCreate: Bool = properties.pendingEntities.contains { $0.property == .collection }
        guard collectionsToCreate == false || properties.entities(of: .publisher).isEmpty == false else { return false }

        if isCreatingWork {
            return trimmedNewWorkTitle.isEmpty == false && addedAuthors.isEmpty == false
        }
        return addedAuthors.isEmpty || work?.isEditable == true
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
        if let author = addedAuthors.first(where: { $0.uri == nil }) {
            return .createAuthor(id: author.id, label: author.trimmedName, language: labelLanguage)
        }
        if isCreatingWork {
            return .createWork(
                label: trimmedNewWorkTitle,
                language: labelLanguage,
                authorUris: addedAuthors.compactMap(\.uri)
            )
        }
        for pending in properties.pendingEntities {
            guard let kind = EntityCreationKind(for: pending.property, publisherUri: properties.publisherUri) else { continue }
            return .createEntity(id: pending.entity.id, label: pending.entity.trimmedLabel, language: labelLanguage, kind: kind)
        }
        return claimUpdates.first.map { .claim($0) }
    }

    /// The claims to send, in order: the edition's title, subtitle, cover and work, then the
    /// authors added to its work. A replacing cover is listed once its hash is known, an author
    /// once it exists, and nothing about a work being created until it is.
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

        if case .existing(let target) = workChange {
            updates.append(update(.work, from: original.workUri, to: target.uri))
        }

        updates += properties.updates(since: original.properties, on: original.uri)

        if let target = work, target.isEditable {
            for case let uri? in addedAuthors.map(\.uri) {
                updates.append(update(.author, of: target.uri, from: nil, to: uri))
            }
        }

        return updates
    }

    // MARK: - What landed

    /// Records the hash a new cover was filed under.
    mutating func coverUploaded(hash: String) {
        uploadedCoverHash = hash
    }

    /// Records the uri an author was created under: it is named from now on.
    mutating func authorCreated(id: UUID, uri: String) {
        guard let index = addedAuthors.firstIndex(where: { $0.id == id }) else { return }
        addedAuthors[index].uri = uri
    }

    /// Records the uri a publisher, a collection or a person was created under.
    mutating func entityCreated(id: UUID, uri: String) {
        properties.entityCreated(id: id, uri: uri)
    }

    /// Records the work created: it is a work inventaire.io has now, written by the authors
    /// added, and only the edition's claim on it is left to send.
    mutating func workCreated(uri: String) {
        workChange = .existing(.init(uri: uri, title: trimmedNewWorkTitle, authors: addedAuthors))
        addedAuthors = []
    }

    /// Records that `update` landed: what it changed now holds its new value, so it drops out of
    /// `claimUpdates`.
    mutating func landed(_ update: EditionClaimUpdate) {
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
            original.workUri = newValue
            if case .existing(let target) = workChange {
                originalWork = target
            }
            workChange = .unchanged
        case nil:
            original.properties.apply(update, from: properties)
        case .author:
            guard let index = addedAuthors.firstIndex(where: { $0.uri == newValue }) else { return }
            let author: NewBookAuthor = addedAuthors.remove(at: index)
            if case .existing(var target) = workChange, target.uri == update.uri {
                target.authors.append(author)
                workChange = .existing(target)
            } else if originalWork?.uri == update.uri {
                originalWork?.authors.append(author)
            }
        }
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
