//
//  ShelfEmptyStateAction.swift
//  ReCIT_iOS
//
//  One paper tag on the empty shelf, and the one thing pressing it does. The tag's wording
//  and the destination both come from this value, so a tag cannot say one thing and open
//  another — the rule the empty card has carried since PRD 0006, kept per tag now that the
//  card carries more than one.
//
//  Only the wording lives here, as in `ShelfEmptyStateErrand`: the destinations are a
//  full-screen cover, a push and a search field, none of them a value this type could hold.
//  `ShelvesContent` switches over the action exactly once to reach the right one.
//

import Foundation

/// Something the empty shelf offers to do, drawn as a paper tag resting on the plank.
enum ShelfEmptyStateAction: Hashable {
    /// Scan books in, with the batch scanner.
    case scan
    /// Look books up by title or author, in the inventory's search field.
    case search
    /// Arrange owned books into étagères, in the sorting surface.
    case sort

    /// The tag's first line — what the press does.
    var title: LocalizedStringResource {
        switch self {
        case .scan:
            "shelf.empty.action.scan.title"
        case .search:
            "shelf.empty.action.search.title"
        case .sort:
            "shelf.empty.action.sort.title"
        }
    }

    /// The tag's second line — how, in a few words.
    var detail: LocalizedStringResource {
        switch self {
        case .scan:
            "shelf.empty.action.scan.detail"
        case .search:
            "shelf.empty.action.search.detail"
        case .sort:
            "shelf.empty.action.sort.detail"
        }
    }

    /// The same glyphs the navigation bar uses for the same two flows, so the tag and the
    /// bar button read as one gesture.
    var systemImage: String {
        switch self {
        case .scan:
            "barcode.viewfinder"
        case .search:
            "magnifyingglass"
        case .sort:
            "books.vertical.fill"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .scan:
            "e2e.shelves.empty.scan"
        case .search:
            "e2e.shelves.empty.search"
        case .sort:
            "e2e.shelves.empty.sort"
        }
    }
}
