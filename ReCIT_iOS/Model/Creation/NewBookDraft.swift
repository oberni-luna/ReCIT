//
//  NewBookDraft.swift
//  ReCIT_iOS
//
//  What the reader has told us about a book inventaire.io does not have yet. A value type with
//  no opinion about the network: the form fills it, `ResolveRequestBuilder` turns it into a
//  request, and nothing else reads it.
//
//  Only two fields are asked for — the title and the author — because they are the only two
//  the barcode cannot answer. The ISBN comes from the camera and is never edited.
//
//  See PRD 0015.
//

import Foundation

struct NewBookDraft: Equatable, Sendable {

    /// The barcode, as the camera read it. May carry hyphens; `normalizedISBN` is what goes on
    /// the wire.
    let isbn: String

    /// The title printed on *this* edition's cover, which is not necessarily the work's.
    var title: String = ""

    /// The author's name as the reader typed it. Becomes a label on a new author entity — or
    /// nothing at all, once an existing author has been chosen (issue 0093).
    var authorName: String = ""

    /// The uri of an author inventaire.io already has, once one has been chosen. `nil` means
    /// the author is being created: the seed then carries labels instead. That single
    /// distinction is what keeps the base free of twin authors.
    var authorUri: String?

    /// What told this author apart from a namesake, kept only to show it back in the form.
    var authorDescription: String?

    /// The cover the reader photographed, as JPEG bytes, before it has been sent anywhere.
    var coverImageData: Data?

    /// Where that photograph ended up once uploaded. `nil` when there was no photograph, and
    /// `nil` when the upload failed — in which case the book is published without it and the
    /// server goes looking for a cover from the ISBN.
    var coverImageUrl: String?

    /// The uri of a work inventaire.io already has, when the reader has agreed that this book
    /// is one more edition of it — picked from the search, or recognised by the reconnaissance
    /// pass. `nil` means a work is being created alongside the edition.
    var workUri: String?

    /// The work picked from the search, kept to show it back at the head of « Nouvelle
    /// édition », and to reopen there when the same barcode comes back. Its uri is `workUri`;
    /// this is the rest of what the row draws.
    var chosenWork: WorkCandidate?

    /// Whether the question « inventaire knows this work — is it yours? » has been put. Asked
    /// at most once per draft: a reader who answered « no, it is another book » must not be
    /// asked again on the retry.
    var hasAnsweredWorkQuestion: Bool = false

    /// What the ISBN says about the language of the book, once the server has been asked.
    /// `nil` until then, and `nil` for good if the call fails — in which case the edition is
    /// published without a language claim rather than with a guessed one.
    var language: EditionLanguage?

    /// The ISBN without its separators, which is the form inventaire.io keys editions by.
    /// `X` survives, being a legitimate ISBN-10 check character.
    var normalizedISBN: String {
        isbn.uppercased().filter { $0.isNumber || $0 == "X" }
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAuthorName: String {
        authorName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether there is enough to publish. An edition with no title is unreadable in every list
    /// it will appear in. A work being created needs its author too — one with none is the kind
    /// of orphan that has to be repaired by hand on the website afterwards — while a work that
    /// already exists brings its own.
    var isPublishable: Bool {
        guard trimmedTitle.isEmpty == false else { return false }
        return workUri != nil || trimmedAuthorName.isEmpty == false
    }

    /// Attaches the edition to a work inventaire.io already has.
    ///
    /// The edition's title starts as the work's, which is right for a reissue and one correction
    /// away for a translation. It is only replaced while the reader has not made it their own:
    /// empty, or still the title of the work picked before this one.
    mutating func choose(_ work: WorkCandidate) {
        if trimmedTitle.isEmpty || title == chosenWork?.title {
            title = work.title
        }
        chosenWork = work
        workUri = work.uri
        // Picked by the reader from the search: there is nothing left for the reconnaissance
        // pass to ask.
        hasAnsweredWorkQuestion = true
    }

    /// Leaves the works the search proposed, to describe one of the reader's own, named after
    /// what they searched for.
    mutating func startNewWork(titled query: String) {
        if trimmedTitle.isEmpty || title == chosenWork?.title {
            title = Self.capitalizingFirstLetter(query.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        chosenWork = nil
        workUri = nil
        hasAnsweredWorkQuestion = false
    }

    /// A title as a search is typed — « étincelles écosocialistes » — made into one as a cover
    /// prints it. Only the first letter: the rest of a title's capitals follow rules of its
    /// language that the reader knows and this does not.
    static func capitalizingFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
