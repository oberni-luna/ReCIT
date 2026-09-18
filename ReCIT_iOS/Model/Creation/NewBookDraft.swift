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

    /// Whether there is enough to publish. Both answers are required: an edition with no title
    /// is unreadable in every list it will appear in, and a work with no author is the kind of
    /// orphan that has to be repaired by hand on the website afterwards.
    var isPublishable: Bool {
        trimmedTitle.isEmpty == false && trimmedAuthorName.isEmpty == false
    }
}
