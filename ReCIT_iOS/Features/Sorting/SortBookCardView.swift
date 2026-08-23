//
//  SortBookCardView.swift
//  ReCIT_iOS
//
//  One book waiting to be filed, in the carousel at the foot of the sorting surface: its
//  cover, face-on, and its title under it.
//
//  It is narrower than an étagère card by design (`SortGridMetrics.bookColumnWidth`), so
//  that a fourth card peeks past the third and the row shows it scrolls. A carousel ending
//  flush at the screen edge looks finished.
//
//  **A tap does nothing.** There is nothing to press: opening a book's screen mid-sort is how a
//  user loses the thread of what they were arranging (PRD 0009).
//
//  **Only the cover is the drag handle.** Attached to the whole card, the drag took every press
//  in the card's transparent margins with it, so the carousel could not be scrolled — the zone
//  read as one big draggable slab. The cover is also the thing that travels, which makes the
//  handle and the payload the same object.
//
//  The cover reserves its 2:3 frame before the image lands, like every cover in the app.
//

import SwiftUI

struct SortBookCardView: View {
    let book: AutoSortBook
    let width: CGFloat
    /// Whether the card hands itself over to a drag. False while a run owns the stack.
    var isDraggable: Bool = true
    /// The étagères this book can be filed into without a drag. Empty while a run owns the
    /// stack, and on any surface that is not offering to rearrange anything.
    var filingOptions: [SortFilingOption] = []
    let onFile: (SortSection.ID) -> Void

    var body: some View {
        VStack(spacing: .xSmall) {
            ShelfCoverView(
                imageUrl: book.coverImageUrl,
                title: book.title,
                size: coverSize
            )
            .sortBookDraggable(book, isEnabled: isDraggable)
            .frame(width: width, height: SortGridMetrics.artHeight)

            Text(book.title)
                .textStyle(.footnote200Bold)
                .foregroundStyle(.foregroundDefault)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, .small)
        .padding(.horizontal, .xSmall)
        .frame(width: width, height: SortGridMetrics.cardHeight)
        // One element rather than a cover and a title: the card is one thing to a reader, and
        // its cover carries no information the title does not.
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            ForEach(filingOptions) { option in
                Button("manual_sort.a11y.file_into \(option.name)") {
                    onFile(option.sectionId)
                }
            }
        }
    }

    /// As wide as the card allows without touching its neighbour, and as tall as that width
    /// makes it — capped at the art's height so a tall format does not push the title out.
    private var coverSize: CGSize {
        let coverWidth: CGFloat = width * 0.6
        return .init(
            width: coverWidth,
            height: min(SortGridMetrics.artHeight, coverWidth / SortGridMetrics.coverAspectRatio)
        )
    }
}
