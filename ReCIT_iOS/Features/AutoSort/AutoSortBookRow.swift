//
//  AutoSortBookRow.swift
//  ReCIT_iOS
//
//  One book as it appears under a proposed étagère. Deliberately not `InventoryCell`:
//  nothing here is filed yet, so there is no transaction state, no availability and
//  nowhere to navigate — the row exists only so the user can recognise the copy and
//  spot a misclassification before it happens. See PRD 0006.
//
//  Shared with the manual sorting surface (PRD 0008), which needs the same row with a
//  drag handle, and without the genre line under « À ranger » — those books are
//  unshelved *for want of* a known genre, so an empty genre line would say the same
//  thing twice. Both are options with the defaults the review screen already had, so
//  that screen is untouched by their existence; they mirror the `Show handle` /
//  genre-off properties the design file carries on this component.
//

import SwiftUI

struct AutoSortBookRow: View {
    let book: AutoSortBook

    /// The genre is the *reason* a book landed on a proposed étagère, so the review
    /// screen always shows it. The unshelved pile turns it off.
    let showsGenre: Bool

    /// The manual sort's move handle. Inert scenery until slice 0038 attaches the
    /// drag to it — the point of drawing it now is that it appears on *every* row,
    /// including the pile's, so the gesture reads as symmetric.
    let showsDragHandle: Bool

    init(
        book: AutoSortBook,
        showsGenre: Bool = true,
        showsDragHandle: Bool = false
    ) {
        self.book = book
        self.showsGenre = showsGenre
        self.showsDragHandle = showsDragHandle
    }

    var body: some View {
        HStack(alignment: .top, spacing: .sMedium) {
            CellThumbnail(imageUrl: book.coverImageUrl, cornerRadius: .minimal, size: .small)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text(book.title)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                if !book.authors.isEmpty {
                    Text(book.authors)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                }

                // The genre is shown because it is the *reason* the book landed here.
                // Without it a misplaced book looks like a whim of the model; with it
                // the user can see whether the genre or the mapping is at fault.
                if showsGenre, let genre = book.primaryGenre {
                    Text(genre)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundTinted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsDragHandle {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.foregroundDisable)
                    // The stack is top-aligned so title and cover line up; the handle
                    // rides the middle of the row instead, which is where a finger
                    // reaching for it expects it.
                    .frame(maxHeight: .infinity)
                    .accessibilityLabel("manual_sort.row.handle")
            }
        }
    }
}
