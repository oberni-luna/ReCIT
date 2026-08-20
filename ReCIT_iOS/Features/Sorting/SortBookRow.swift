//
//  SortBookRow.swift
//  ReCIT_iOS
//
//  One book as it appears on the sorting surface. Deliberately not `InventoryCell`:
//  what is drawn here is a book being *arranged*, so there is no transaction state, no
//  availability and nowhere to navigate — the row exists so the user can recognise the
//  copy and spot a misclassification before it happens.
//
//  It was `AutoSortBookRow`, under `Features/AutoSort/`, and moved here when PRD 0008
//  retired the review screen it was written for. The sorting surface is now its only
//  reader, on both sides of the drag: the list rows and the lifted preview.
//
//  Its two options mirror the `Show handle` / genre-off properties the design file
//  carries on this component. The genre is off under « À ranger » — those books are
//  unshelved *for want of* a known genre, so an empty genre line would say the same
//  thing twice.
//
//  See PRD 0006 and PRD 0008.
//

import SwiftUI

struct SortBookRow: View {
    let book: AutoSortBook

    /// The genre is the *reason* a book was proposed for an étagère, so a row under one
    /// shows it. The unshelved pile turns it off.
    let showsGenre: Bool

    /// The move handle. Drawn on *every* row, including the pile's, so the gesture reads
    /// as symmetric — the whole row is draggable, and the handle is what says so.
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

                // The genre is shown because it is the *reason* a proposal put the
                // book here. Without it a misplaced book looks like a whim of the
                // model; with it the user can see whether the genre or the mapping is
                // at fault.
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
