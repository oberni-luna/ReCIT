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
//  **A tap does nothing.** The card is a handle for the drag and nothing else: opening a
//  book's screen mid-sort is how a user loses the thread of what they were arranging
//  (PRD 0009). Which is also why there is no `Button` here — nothing to press.
//
//  The cover reserves its 2:3 frame before the image lands, like every cover in the app.
//

import SwiftUI

struct SortBookCardView: View {
    let book: AutoSortBook
    let width: CGFloat

    var body: some View {
        VStack(spacing: .xSmall) {
            ShelfCoverView(
                imageUrl: book.coverImageUrl,
                title: book.title,
                size: coverSize
            )
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
