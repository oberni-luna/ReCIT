//
//  ShelfBooksView.swift
//  ReCIT_iOS
//
//  Thin SwiftUI renderer over `ShelfBooksLayout`: it maps books to page counts, asks the
//  layout for the mode and geometry, and draws spines / a pile / a single cover
//  accordingly. All layout math lives in the (testable) layout type. See ADR 0003.
//

import SwiftUI

struct ShelfBooksView: View {
    let books: [InventoryItem]
    let width: CGFloat
    let zoneHeight: CGFloat
    let scrubIndex: Int?

    /// Horizontal inset so the outermost books sit on the plank rather than at the very
    /// edge of the card. The books lay out within this reduced width, centred; the plank
    /// stays full width.
    static let horizontalMargin: CGFloat = 24
    private var booksWidth: CGFloat { max(width - Self.horizontalMargin * 2, 0) }

    private var layout: ShelfBooksLayout {
        ShelfBooksLayout(
            pageCounts: books.map { $0.edition?.numberOfPages },
            width: booksWidth,
            zoneHeight: zoneHeight
        )
    }

    var body: some View {
        Group {
            switch layout.mode {
            case .singleCover:
                singleCover
            case .allVertical:
                verticalRun(range: 0..<books.count)
            case .mixed(let verticalCount):
                HStack(alignment: .bottom, spacing: 0) {
                    verticalRun(range: 0..<verticalCount)
                        .frame(width: booksWidth / 2, alignment: .leading)
                    pileRun(range: verticalCount..<books.count)
                        .frame(width: booksWidth / 2, alignment: .trailing)
                }
            }
        }
        .frame(width: width, height: zoneHeight, alignment: .bottom)
        // Sit the books a touch into the plank for a more convincing 3D "on the shelf" look.
        .offset(y: 4)
    }

    private func verticalRun(range: Range<Int>) -> some View {
        HStack(alignment: .bottom, spacing: ShelfBooksLayout.spacing) {
            ForEach(range, id: \.self) { index in
                ShelfSpineView(item: books[index], size: layout.spineSize(at: index))
                    .rotationEffect(layout.isLeaning(at: index) ? .degrees(-ShelfBooksLayout.leanDegrees) : .zero, anchor: .bottomTrailing)
                    .offset(x: layout.isLeaning(at: index) ? layout.leanOffset(at: index) : 0)
                    .scaleEffect(scrubIndex == index ? 1.5 : 1, anchor: .center)
                    .zIndex(scrubIndex == index ? 1 : 0)
                    .animation(.spring(duration: 0.22), value: scrubIndex)
            }
        }
    }

    private func pileRun(range: Range<Int>) -> some View {
        VStack(spacing: -1) {
            ForEach(range, id: \.self) { index in
                pileBar(index)
                    .offset(x: layout.pileJitter(at: index))
                    .scaleEffect(scrubIndex == index ? 1.5 : 1)
                    .zIndex(scrubIndex == index ? 1 : 0)
                    .animation(.spring(duration: 0.22), value: scrubIndex)
            }
        }
    }

    private func pileBar(_ index: Int) -> some View {
        let item: InventoryItem = books[index]
        return PaintedBookView(
            edition: item.edition,
            size: layout.pileBarSize(at: index, availableWidth: booksWidth / 2)
        ) { ink in
            Text(item.edition?.title ?? "")
                .textStyle(.footnote200Bold)
                .foregroundStyle(ink)
                .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 0.5)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
        }
    }

    /// A lone book is shown face-on with its real cover — prettier than a single spine.
    private var singleCover: some View {
        let item: InventoryItem = books[0]
        let coverHeight: CGFloat = zoneHeight * 0.98
        let coverWidth: CGFloat = coverHeight * 0.66
        let url: URL? = item.edition?.image.flatMap { URL(string: $0) }
        return CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(ShelfPalette.parchment)
                Text(item.edition?.title ?? "")
                    .textStyle(.caption200)
                    .foregroundStyle(.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    .padding(4)
            }
        }
        .frame(width: coverWidth, height: coverHeight)
        .clipShape(.rect(cornerRadius: 2))
        .shadow(color: .black.opacity(0.22), radius: 3, x: 1, y: 2)
        .scaleEffect(scrubIndex == 0 ? 1.5 : 1, anchor: .center)
        .animation(.spring(duration: 0.22), value: scrubIndex)
    }
}
