//
//  OtherEditionsCell.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//
//  Row in BookDetailView pointing to the other editions of an underlying work.
//  Mirrors the book-list cover cell: rounded-square work image, work title, and
//  a static "Autres éditions" subtitle.
//

import SwiftUI

struct OtherEditionsCell: View {
    let work: Work

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CellThumbnail(imageUrl: work.image)

            VStack(alignment: .leading, spacing: 4) {
                Text(work.title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)

                Text("book.other_editions_subtitle")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }
}
