//
//  SortBookDraggable.swift
//  ReCIT_iOS
//
//  Makes a view the handle for one book's drag, or leaves it alone — the conditional being
//  the point: the same cover is draggable on the sorting grid and inert while a run owns the
//  stack, and a screen that offers a drag which the session will refuse is worse than one
//  that offers nothing.
//
//  The preview is the cover, at the size the caller draws it. Never the card: what travels is
//  a book, and a card-sized preview would say the étagère is moving.
//

import SwiftUI

extension View {

    /// Lets `book` be dragged from this view, when `isEnabled`.
    func sortBookDraggable(
        _ book: AutoSortBook,
        coverSize: CGSize,
        isEnabled: Bool = true
    ) -> some View {
        modifier(SortBookDraggable(book: book, coverSize: coverSize, isEnabled: isEnabled))
    }
}

struct SortBookDraggable: ViewModifier {
    let book: AutoSortBook
    let coverSize: CGSize
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.draggable(SortBookTransfer(bookId: book.id)) {
                ShelfCoverView(
                    imageUrl: book.coverImageUrl,
                    title: book.title,
                    size: coverSize
                )
            }
        } else {
            content
        }
    }
}
