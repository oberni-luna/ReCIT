//
//  NewBookDraft.swift
//  ReCIT_iOS
//
//  What the reader has told us about a book inventaire.io does not have yet. A value type with
//  no opinion about the network: the screens fill it, `ResolveRequestBuilder` turns it into a
//  request, and nothing else reads it.
//
//  Two shapes, decided by the work search the sheet opens on. A work inventaire.io already has:
//  `workUri` names it, and only the edition is described — its title, its cover. A work of the
//  reader's own: its title and its authors are described too, and created with the edition.
//  The ISBN comes from the camera and is never edited. Everything else inventaire.io accepts on
//  an edition — publisher, date, format, contributors, identifiers — is `properties`, the same
//  value « Modifier l'édition » holds.
//
//  See PRD 0015 and PRD 0026.
//

import Foundation

struct NewBookDraft: Equatable, Sendable {

    /// The barcode, as the camera read it. May carry hyphens; `normalizedISBN` is what goes on
    /// the wire.
    let isbn: String

    /// The title printed on *this* edition's cover, which is not necessarily the work's: a
    /// translation, a reissue and a boxed set share a work and disagree about their covers.
    var title: String = ""

    /// The subtitle printed on this edition, if any.
    var subtitle: String = ""

    /// The publisher, collection, date, language, format, contributors, identifiers and links.
    var properties: EditionProperties = .init()

    /// The title of the work being created, when none of the works found was the book.
    var workTitle: String = ""

    /// Who wrote the work being created — one or several, each either an author inventaire.io
    /// already has or one created with the book.
    var authors: [NewBookAuthor] = []

    /// The cover, as JPEG bytes, before it has been sent anywhere.
    var coverImageData: Data?

    /// Where that cover can be fetched from by inventaire.io: the url the upload answered, made
    /// absolute. `nil` when there is no cover, and `nil` when the upload failed — in which case
    /// the book is published without it and the server goes looking for one from the ISBN.
    var coverImageUrl: String?

    /// The uri of a work inventaire.io already has, when this book is one more edition of it —
    /// picked from the search, or recognised by the reconnaissance pass. `nil` means a work is
    /// being created alongside the edition.
    var workUri: String?

    /// The work picked from the search, kept to show it back at the head of « Nouvelle
    /// édition », and to reopen there when the same barcode comes back. Its uri is `workUri`;
    /// this is the rest of what the row draws.
    var chosenWork: WorkCandidate?

    /// Whether the question « inventaire knows this work — is it yours? » has been put. Asked
    /// at most once per draft: a reader who answered « no, it is another work » must not be
    /// asked again on the retry.
    var hasAnsweredWorkQuestion: Bool = false

    /// What the ISBN says about the language of the book, once the server has been asked.
    /// `nil` until then, and `nil` for good if the call fails — in which case the edition is
    /// published without a language claim rather than with a guessed one.
    var language: EditionLanguage? {
        didSet {
            // What the ISBN says becomes the edition's language, unless the reader has chosen
            // one: the form shows it, and the reader can change it there.
            guard let language, properties.entities(of: .language).isEmpty else { return }
            properties.add(.init(uri: language.uri, label: language.localizedName ?? language.code), to: .language)
        }
    }

    /// The cover as the forms set it: a new picture, or none. Either way the one already
    /// uploaded, if the reader is retrying after a failure, no longer stands — the next
    /// publication sends what is here now.
    var cover: Data? {
        get { coverImageData }
        set {
            coverImageData = newValue
            coverImageUrl = nil
        }
    }

    /// The title the image search for a cover asks for: the work's, which is what a cover is
    /// known by, or this edition's when there is no work title yet.
    var coverSearchTitle: String {
        let work: String = chosenWork?.title ?? trimmedWorkTitle
        return work.isEmpty ? trimmedTitle : work
    }

    /// The ISBN without its separators, which is the form inventaire.io keys editions by.
    /// `X` survives, being a legitimate ISBN-10 check character.
    var normalizedISBN: String {
        isbn.uppercased().filter { $0.isNumber || $0 == "X" }
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubtitle: String {
        subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedWorkTitle: String {
        workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The authors worth sending: a row left without a name is no author.
    var namedAuthors: [NewBookAuthor] {
        authors.filter { $0.trimmedName.isEmpty == false }
    }

    /// Whether there is enough to publish. An edition with no title is unreadable in every list
    /// it will appear in. A work being created needs its title and an author too — one with
    /// none is the kind of orphan that has to be repaired by hand on the website afterwards —
    /// while a work that already exists brings its own.
    var isPublishable: Bool {
        guard trimmedTitle.isEmpty == false else { return false }

        // A collection is created under its publisher: one with no publisher to be created
        // under could not be.
        let collectionsToCreate: Bool = properties.pendingEntities.contains { $0.property == .collection }
        guard collectionsToCreate == false || properties.entities(of: .publisher).isEmpty == false else { return false }

        if workUri != nil { return true }
        return trimmedWorkTitle.isEmpty == false && namedAuthors.isEmpty == false
    }

    /// Whether the draft names a work: one inventaire.io has, or one being described.
    var hasWork: Bool {
        workUri != nil || trimmedWorkTitle.isEmpty == false
    }

    /// What a swipe on « Détacher » takes away: the work, picked or being described. The
    /// reader goes back to the search for another.
    mutating func detachWork() {
        chosenWork = nil
        workUri = nil
        workTitle = ""
        authors = []
        hasAnsweredWorkQuestion = false
    }

    /// Whether the edition's title is still the one this draft gave it — empty, or copied from
    /// a work — rather than one the reader typed. Only then does it follow the work's.
    private var titleFollowsWork: Bool {
        trimmedTitle.isEmpty || title == workTitle || title == chosenWork?.title
    }

    /// Attaches the edition to a work inventaire.io already has.
    ///
    /// The edition's title starts as the work's, which is right for a reissue and one correction
    /// away for a translation.
    mutating func choose(_ work: WorkCandidate) {
        if titleFollowsWork { title = work.title }
        chosenWork = work
        workUri = work.uri
        // Picked by the reader from the search: there is nothing left for the reconnaissance
        // pass to ask.
        hasAnsweredWorkQuestion = true
    }

    /// Leaves the works the search proposed, to describe one of the reader's own, named after
    /// what they searched for.
    mutating func startNewWork(titled query: String) {
        let named: String = Self.capitalizingFirstLetter(query.trimmingCharacters(in: .whitespacesAndNewlines))
        if titleFollowsWork { title = named }
        workTitle = named
        chosenWork = nil
        workUri = nil
        hasAnsweredWorkQuestion = false
    }

    /// Renames the work being created, carrying the edition's title along while the reader has
    /// not made it their own.
    mutating func renameWork(_ newTitle: String) {
        if titleFollowsWork { title = newTitle }
        workTitle = newTitle
    }

    /// A title as a search is typed — « étincelles écosocialistes » — made into one as a cover
    /// prints it. Only the first letter: the rest of a title's capitals follow rules of its
    /// language that the reader knows and this does not.
    static func capitalizingFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
