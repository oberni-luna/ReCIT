//
//  WorkRow.swift
//  ReCIT_iOS
//
//  One work, as the reader has to recognise it: the whole cover, the title, and who wrote it
//  when. `Form / Work Row` (`711:21157`) in the « Nouveau livre v2 » section of the Figma file.
//
//  Not `CellThumbnail`: its book is a 3:4 vignette, and recognising the book in one's hand
//  takes the cover's real 2:3. Not a `NavigationLink` either — the row is the label of a button
//  that writes the choice into the draft before pushing, so the disclosure chevron is drawn here
//  when the row leads somewhere, and left out when it only recalls a choice already made.
//
//  See PRD 0021.
//

import SwiftUI

struct WorkRow: View {
    let work: WorkCandidate

    /// Whether the row leads to another screen, and says so with a chevron.
    var showsDisclosure: Bool = false

    var body: some View {
        HStack(spacing: .sMedium) {
            WorkRowCover(imageUrl: work.imageUrl)

            VStack(alignment: .leading, spacing: .xxSmall) {
                Text(work.title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)

                if let detail = work.detail, detail.isEmpty == false {
                    Text(detail)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .textStyle(.footnote200Bold)
                    .foregroundStyle(.foregroundPlaceholder)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// The cover at 36 × 54, or the grey a work without an image has on inventaire.io.
private struct WorkRowCover: View {
    let imageUrl: String?

    var body: some View {
        ZStack {
            DesignSystem.Color.backgroundSecondary.color

            if let imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    EmptyView()
                }
            }
        }
        .frame(width: 36, height: 54)
        // A book's corner, as `ShelfBooksView` draws it: off the radius scale on purpose.
        .clipShape(.rect(cornerRadius: 2))
        .accessibilityHidden(true)
    }
}
