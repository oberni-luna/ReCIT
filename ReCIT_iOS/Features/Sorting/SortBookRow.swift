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
//  retired the review screen it was written for.
//
//  Measurements are the design's own (`Tri manuel · Light`, node `115:3278`): a 36 pt
//  cover, 12 pt between the columns, 4 pt between title and author.
//
//  Since PRD 0009 its only reader is `SortShelfDetailView` — the surface itself draws books as
//  cards now — so the row keeps the plain `List` insets rather than the card background the
//  old flattened list needed.
//
//  **No genre line.** The design shows a genre under each row, but the live data behind it is
//  Wikidata's `wdt:P136` claims, which return things like « Figure d'autorité » — a label that
//  says nothing about a book and reads as a bug. A recorded divergence.
//
//  See PRD 0006 and PRD 0008.
//

import SwiftUI

struct SortBookRow: View {
    let book: AutoSortBook

    var body: some View {
        HStack(alignment: .top, spacing: .sMedium) {
            CellThumbnail(imageUrl: book.coverImageUrl, cornerRadius: .minimal, size: .small)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text(book.title)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(2)

                if book.authors.isEmpty == false {
                    Text(book.authors)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        // Clamped where the design shows a single author. A copy with six
                        // of them would otherwise double the row's height, and a list
                        // whose rows are all different heights is a list nobody can scan
                        // for the book they are looking for.
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
