//
//  ManualSortBookRowView.swift
//  ReCIT_iOS
//
//  One book on the sorting surface, and the gesture that files it.
//
//  The whole row is draggable, not just the handle. The handle is an affordance — it
//  says *this row moves* — and making it the only grip would mean the row a finger
//  actually lands on does nothing. There is no edit mode either: the drag crosses
//  sections, which `List`'s built-in move cannot do, so the row is dragged as it
//  stands (PRD 0008).
//
//  The payload carries the section the book is leaving as well as the book, because a
//  move records both ends — see `SortBookTransfer`.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortBookRowView: View {

    let book: AutoSortBook

    /// The section this row is drawn under — the origin of any drag started here.
    let section: SortSection

    var body: some View {
        SortBookRow(
            book: book,
            // The pile's books are unshelved *for want of* a known genre, so an empty
            // genre line under them would state the same fact twice.
            showsGenre: section.isUnshelved == false,
            showsDragHandle: true
        )
        .draggable(SortBookTransfer(bookId: book.id, origin: section.id)) {
            ManualSortDragPreview(book: book, showsGenre: section.isUnshelved == false)
        }
    }
}
