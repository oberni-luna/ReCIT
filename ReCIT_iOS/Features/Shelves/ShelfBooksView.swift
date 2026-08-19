//
//  ShelfBooksView.swift
//  ReCIT_iOS
//
//  Thin SwiftUI renderer over `ShelfBooksLayout`: given the layout (built by the parent,
//  which also uses it to find the book under the finger) it draws spines / a pile / a single
//  cover, growing the pressed one. All layout math lives in the (testable) layout type.
//  See ADR 0003 / ADR 0006.
//

import SwiftUI

struct ShelfBooksView: View {
    let books: [InventoryItem]
    let metrics: ShelfCardMetrics
    let layout: ShelfBooksLayout
    /// The book under the finger, drawn above the others at `growth`.
    let grownIndex: Int?
    /// How much that book has grown (1 = at rest). The parent animates it.
    let growth: CGFloat

    private var width: CGFloat { metrics.width }
    private var booksWidth: CGFloat { layout.width }
    private var zoneHeight: CGFloat { layout.zoneHeight }

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
                    .scaleEffect(grownIndex == index ? growth : 1, anchor: .center)
                    .zIndex(grownIndex == index ? 1 : 0)
            }
        }
    }

    private func pileRun(range: Range<Int>) -> some View {
        VStack(spacing: -1) {
            ForEach(range, id: \.self) { index in
                pileBar(index)
                    .offset(x: layout.pileJitter(at: index))
                    .scaleEffect(grownIndex == index ? growth : 1)
                    .zIndex(grownIndex == index ? 1 : 0)
            }
        }
    }

    private func pileBar(_ index: Int) -> some View {
        let item: InventoryItem = books[index]
        return PaintedBookView(
            edition: item.edition,
            size: layout.pileBarSize(at: index, availableWidth: layout.pileColumnWidth),
            orientation: .lying
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
        let coverHeight: CGFloat = zoneHeight * ShelfBooksLayout.singleCoverHeightFraction
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
        .scaleEffect(grownIndex == 0 ? growth : 1, anchor: .center)
    }
}
