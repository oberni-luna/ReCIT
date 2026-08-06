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

    private var layout: ShelfBooksLayout {
        ShelfBooksLayout(
            pageCounts: books.map { $0.edition?.numberOfPages },
            width: width,
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
                        .frame(width: width / 2, alignment: .leading)
                    pileRun(range: verticalCount..<books.count)
                        .frame(width: width / 2, alignment: .trailing)
                }
            }
        }
        .frame(width: width, height: zoneHeight, alignment: .bottom)
    }

    private func verticalRun(range: Range<Int>) -> some View {
        HStack(alignment: .bottom, spacing: ShelfBooksLayout.spacing) {
            ForEach(range, id: \.self) { index in
                ShelfSpineView(item: books[index], size: layout.spineSize(at: index), seed: ShelfBooksLayout.seed(index))
                    .rotationEffect(layout.isLeaning(at: index) ? .degrees(-ShelfBooksLayout.leanDegrees) : .zero, anchor: .bottomTrailing)
                    .offset(x: layout.isLeaning(at: index) ? layout.leanOffset(at: index) : 0)
                    .scaleEffect(scrubIndex == index ? 1.5 : 1, anchor: .bottom)
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
            size: layout.pileBarSize(at: index, availableWidth: width / 2),
            seed: ShelfBooksLayout.seed(index)
        ) { ink in
            Text(item.edition?.title ?? "")
                .textStyle(.footnote200Bold)
                .foregroundStyle(ink)
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
        .scaleEffect(scrubIndex == 0 ? 1.5 : 1, anchor: .bottom)
        .animation(.spring(duration: 0.22), value: scrubIndex)
    }
}
