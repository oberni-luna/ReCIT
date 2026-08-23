//
//  SortBookDraggable.swift
//  ReCIT_iOS
//
//  Makes a view the handle for one book's drag, or leaves it alone — the conditional being
//  the point: the same cover is draggable on the sorting grid and inert while a run owns the
//  stack, and a screen that offers a drag which the session will refuse is worse than one
//  that offers nothing.
//
//  **No preview closure.** The lifted object is the view this is attached to, which is the cover
//  itself — so what travels is a book, not the card around it. A closure was tried first and it
//  produced a parchment slab with a title on it: a closure builds a *fresh* `CachedAsyncImage`,
//  and the drag session snapshots it before Nuke has handed the image over. The source view has
//  its image already.
//

import SwiftUI

extension View {

    /// Lets `book` be dragged from this view, when `isEnabled`. Attach it to the **cover**, not
    /// to the card: a card-sized handle turns every press in its transparent margins into a
    /// drag, which is what stops the carousel scrolling.
    func sortBookDraggable(
        _ book: AutoSortBook,
        isEnabled: Bool = true
    ) -> some View {
        modifier(SortBookDraggable(book: book, isEnabled: isEnabled))
    }
}

struct SortBookDraggable: ViewModifier {
    let book: AutoSortBook
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.draggable(SortBookTransfer(bookId: book.id))
        } else {
            content
        }
    }
}
