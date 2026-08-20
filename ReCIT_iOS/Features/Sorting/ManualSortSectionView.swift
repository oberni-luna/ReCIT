//
//  ManualSortSectionView.swift
//  ReCIT_iOS
//
//  One band of the sorting surface: a header and the books under it.
//
//  Its own type rather than a `@ViewBuilder` inside the list so that the section is
//  the unit the drag lands on (slice 0038) — a drop destination has to be attached to
//  something, and that something should be the same thing the header names.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortSectionView: View {
    let section: SortSection

    var body: some View {
        Section {
            ForEach(section.books) { book in
                AutoSortBookRow(
                    book: book,
                    // The pile's books are unshelved *for want of* a known genre, so
                    // an empty genre line under them would state the same fact twice.
                    showsGenre: section.isUnshelved == false,
                    showsDragHandle: true
                )
            }
        } header: {
            ManualSortSectionHeader(section: section)
        }
    }
}
