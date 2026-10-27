//
//  EditionComparison.swift
//  ReCIT_iOS
//
//  « Ce qui diffère » between the two editions of a pair, and « Pareil : … » for the rest. Pure:
//  each side is a plain value read once off its `Edition`.
//
//  A value an edition lacks is `nil`, and differs from one the other has. Two ISBNs are compared
//  normalized — an ISBN-10 and its ISBN-13 are the same —, and shown as each edition writes it.
//
//  See PRD 0028.
//

import Foundation

struct EditionComparison: Equatable {

    enum Property: CaseIterable, Equatable, Sendable {
        case title
        case isbn
        case publisher
        case publicationDate
        case pages
        case cover
        case language
        case work
    }

    /// What is compared of one edition.
    struct Side: Equatable, Sendable {
        let title: String
        let isbn: String?
        let publisher: String?
        let publicationDate: String?
        let pages: Int?
        let hasCover: Bool
        let language: String?
        let workUris: Set<String>

        @MainActor
        init(edition: Edition) {
            self.init(
                title: edition.title,
                isbn: edition.isbn,
                publisher: edition.publisherName ?? edition.publisherUri,
                publicationDate: edition.publicationDate,
                pages: edition.numberOfPages,
                hasCover: edition.image?.isEmpty == false,
                language: edition.lang,
                workUris: Set(edition.workUris)
            )
        }

        init(
            title: String,
            isbn: String? = nil,
            publisher: String? = nil,
            publicationDate: String? = nil,
            pages: Int? = nil,
            hasCover: Bool = false,
            language: String? = nil,
            workUris: Set<String> = []
        ) {
            self.title = title
            self.isbn = isbn
            self.publisher = publisher
            self.publicationDate = publicationDate
            self.pages = pages
            self.hasCover = hasCover
            self.language = language
            self.workUris = workUris
        }
    }

    /// One line of « Ce qui diffère »: the property, and each side's value — `nil` when the
    /// edition has none. The cover is `"yes"` / `"no"`, for the view to say in words.
    struct Row: Equatable, Sendable {
        let property: Property
        let first: String?
        let second: String?
    }

    let differences: [Row]
    let sameProperties: [Property]

    init(first: Side, second: Side) {
        var differences: [Row] = []
        var same: [Property] = []

        for property in Property.allCases {
            let (left, right): (String?, String?) = (Self.value(of: property, in: first), Self.value(of: property, in: second))
            if Self.key(of: property, in: first) == Self.key(of: property, in: second) {
                same.append(property)
            } else if property != .work {
                differences.append(.init(property: property, first: left, second: right))
            }
        }

        self.differences = differences
        self.sameProperties = same
    }

    /// The value shown for `property`.
    private static func value(of property: Property, in side: Side) -> String? {
        switch property {
        case .title: side.title
        case .isbn: side.isbn
        case .publisher: side.publisher
        case .publicationDate: side.publicationDate
        case .pages: side.pages.map(String.init)
        case .cover: side.hasCover ? "yes" : "no"
        case .language: side.language
        case .work: side.workUris.sorted().joined(separator: "|")
        }
    }

    /// The value compared for `property`: the shown one, except an ISBN, compared normalized.
    private static func key(of property: Property, in side: Side) -> String? {
        switch property {
        case .isbn:
            IsbnNormalization.normalized(side.isbn) ?? side.isbn
        default:
            value(of: property, in: side)
        }
    }
}
