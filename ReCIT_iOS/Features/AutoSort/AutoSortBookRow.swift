//
//  AutoSortBookRow.swift
//  ReCIT_iOS
//
//  One book as it appears under a proposed étagère. Deliberately not `InventoryCell`:
//  nothing here is filed yet, so there is no transaction state, no availability and
//  nowhere to navigate — the row exists only so the user can recognise the copy and
//  spot a misclassification before it happens. See PRD 0006.
//

import SwiftUI

struct AutoSortBookRow: View {
    let book: AutoSortBook

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
                if let genre = book.primaryGenre {
                    Text(genre)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundTinted)
                }
            }
        }
    }
}
