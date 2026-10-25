//
//  WorkEdit.swift
//  ReCIT_iOS
//
//  One work of the edition, as « Édition de » lists it and « Modifier l'œuvre » changes it: its
//  title and its authors, against what inventaire.io holds. A work that exists is renamed by
//  `update-label` and given or relieved of authors by `wdt:P50` claims on it; one still to be
//  created is described here, and created with its authors before the edition names it.
//
//  A Wikidata work is shown and not changed: its title and authors are edited on Wikidata,
//  through an account this app does not hold.
//

import Foundation

struct WorkEdit: Identifiable, Equatable, Sendable {

    /// The row's own identity: a work being created has no uri yet.
    let id: UUID

    /// The work as inventaire.io holds it, after every change that landed. `nil` while it is
    /// still to be created.
    private(set) var original: EditionWork?

    var title: String

    /// Who wrote it, as the form has them. One inventaire.io does not have gets its uri once
    /// created, so a retry does not create them twice.
    private(set) var authors: [NewBookAuthor]

    /// The picture the row shows.
    var imageUrl: String?

    /// A work inventaire.io or Wikidata has.
    init(original: EditionWork) {
        id = .init()
        self.original = original
        title = original.title
        authors = original.authors
        imageUrl = original.imageUrl
    }

    /// A work to create, named after the search that did not find it.
    init(newTitled title: String) {
        id = .init()
        original = nil
        self.title = NewBookDraft.capitalizingFirstLetter(title.trimmingCharacters(in: .whitespacesAndNewlines))
        authors = []
    }

    var uri: String? {
        original?.uri
    }

    var isNew: Bool {
        original == nil
    }

    /// One of inventaire.io's own, or one to create. A Wikidata work is changed on Wikidata.
    var isEditable: Bool {
        original?.isEditable ?? true
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - What changed

    /// The new title of a work that exists, when it was changed.
    var renamedTitle: String? {
        guard let original, isEditable, trimmedTitle.isEmpty == false,
              trimmedTitle != original.title.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return trimmedTitle
    }

    var addedAuthors: [NewBookAuthor] {
        guard let original else { return authors }
        return authors.filter { author in original.authors.contains { Self.isSamePerson($0, author) } == false }
    }

    var removedAuthors: [NewBookAuthor] {
        guard let original else { return [] }
        return original.authors.filter { author in authors.contains { Self.isSamePerson($0, author) } == false }
    }

    var hasChanges: Bool {
        isNew || renamedTitle != nil || addedAuthors.isEmpty == false || removedAuthors.isEmpty == false
    }

    /// Whether it can be saved: a title, and — for a work being created — an author. A work
    /// created with neither is the kind of orphan that has to be repaired by hand on the website.
    var isComplete: Bool {
        guard trimmedTitle.isEmpty == false else { return isEditable == false }
        return isNew == false || authors.isEmpty == false
    }

    // MARK: - Changing

    /// Adds an author, unless they are on the work already.
    mutating func addAuthor(_ author: NewBookAuthor) {
        guard isEditable, author.trimmedName.isEmpty == false,
              authors.contains(where: { Self.isSamePerson($0, author) }) == false else { return }
        authors.append(author)
    }

    /// What a swipe on the list of authors takes away.
    mutating func removeAuthors(atOffsets offsets: IndexSet) {
        guard isEditable else { return }
        for index in offsets.sorted(by: >) where authors.indices.contains(index) {
            authors.remove(at: index)
        }
    }

    // MARK: - What landed

    /// Records the uri an author was created under. Answers whether the author was this work's.
    @discardableResult
    mutating func authorCreated(id: UUID, uri: String) -> Bool {
        guard let index = authors.firstIndex(where: { $0.id == id }) else { return false }
        authors[index].uri = uri
        return true
    }

    /// Records the work created: it exists now, with the title and authors it was created with.
    mutating func created(uri: String, titleLanguage: String) {
        original = .init(uri: uri, title: trimmedTitle, authors: authors, imageUrl: imageUrl, titleLanguage: titleLanguage)
    }

    /// Records that an author claim landed on the work: `added` is on it, `removed` is not.
    mutating func authorLanded(added: String?, removed: String?) {
        if let removed {
            original?.authors.removeAll { $0.uri == removed }
        }
        if let added, let author = authors.first(where: { $0.uri == added }) {
            original?.authors.append(author)
        }
    }

    /// Records that the new title landed.
    mutating func titleLanded(_ value: String) {
        original?.title = value
    }

    // MARK: - Showing

    /// The work as `WorkRow` draws it: its title, and its authors on the line under it.
    var candidate: WorkCandidate {
        .init(
            uri: uri ?? "",
            title: trimmedTitle,
            authors: authors.map(\.trimmedName).filter { $0.isEmpty == false },
            year: nil,
            summary: nil,
            imageUrl: imageUrl
        )
    }

    /// The same uri, or — when one side has none, as authors picked from the search do — the
    /// same name.
    static func isSamePerson(_ lhs: NewBookAuthor, _ rhs: NewBookAuthor) -> Bool {
        if let left = lhs.uri, let right = rhs.uri { return left == right }
        return lhs.trimmedName.localizedCaseInsensitiveCompare(rhs.trimmedName) == .orderedSame
    }
}
