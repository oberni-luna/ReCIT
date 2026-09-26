//
//  ListCoverPreview.swift
//  ReCIT_iOS
//
//  Which of a list's elements the Lists tab shows as covers: the first few, in the order the
//  list itself keeps them — the same `ordinal` sort as `EntityListDetail`, so the row previews
//  what opening the list shows first. Pure, so it can be tested without a store.
//

import Foundation

enum ListCoverPreview {
    /// How many covers a row fans out.
    static let limit: Int = 3

    static func uris(
        of elements: [EntityListItem],
        limit: Int = limit
    ) -> [String] {
        let ordered: [EntityListItem] = elements.sorted { $0.ordinal < $1.ordinal }
        var seen: Set<String> = []
        var uris: [String] = []
        for element in ordered where uris.count < limit {
            guard seen.insert(element.uri).inserted else { continue }
            uris.append(element.uri)
        }
        return uris
    }
}
