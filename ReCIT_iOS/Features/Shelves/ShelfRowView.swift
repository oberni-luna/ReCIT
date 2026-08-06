//
//  ShelfRowView.swift
//  ReCIT_iOS
//
//  One étagère: the watercolour wash, the books (spines or pile), the wooden plank,
//  and the shelf name beneath. Tap opens the shelf's list; a horizontal swipe scrubs
//  the books (zoom + haptic) and, on release, opens the book under the finger.
//
//  Sizing is driven entirely by the `width` passed in (the grid cell width) so the
//  view returns a deterministic size — self-measuring here caused a UICollectionView
//  update loop when hosted in a List. See ADR 0003.
//

import SwiftUI

struct ShelfRowView: View {
    let shelf: Shelf
    let width: CGFloat
    @Binding var path: NavigationPath

    @State private var scrubIndex: Int?
    @State private var isScrubbing: Bool = false

    /// Books shown on the shelf, newest first, capped so a huge shelf doesn't render
    /// hundreds of spines (the overflow is reachable via the shelf's list).
    private var books: [InventoryItem] {
        Array(shelf.items.sorted { $0.created > $1.created }.prefix(18))
    }

    private var plankHeight: CGFloat { width * 129.0 / 820.0 }
    private var zoneHeight: CGFloat { width * 9.0 / 16.0 }

    var body: some View {
        VStack(spacing: .xSmall) {
            shelfStack
            Text(shelf.name)
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundDefault)
                .lineLimit(1)
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .onTapGesture { path.append(NavigationDestination.shelf(id: shelf._id)) }
        .gesture(scrubGesture)
        .sensoryFeedback(.selection, trigger: scrubIndex)
    }

    private var shelfStack: some View {
        ZStack(alignment: .bottom) {
            // Wash centred vertically on the plank: constrained to a plank-height box
            // pinned to the bottom, so the (taller) blob overflows equally above the
            // books and below the shelf, with its centre on the plank.
            Image("ShelfWash")
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .offset(y: (width * 672.0 / 1024.0 - plankHeight) / 2)
                .opacity(0.92)
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                ShelfBooksView(
                    books: books,
                    width: width,
                    zoneHeight: zoneHeight,
                    scrubIndex: scrubIndex
                )
                Image("ShelfPlank")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: zoneHeight + plankHeight)
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard width > 0, books.isEmpty == false else { return }

                // Leaving the shelf area (in ANY direction) deselects and arms a no-op
                // release, so the user can bail out of a scrub by sliding off the shelf.
                let contentHeight: CGFloat = zoneHeight + plankHeight
                let inBounds: Bool = value.location.x >= 0
                    && value.location.x <= width
                    && value.location.y >= 0
                    && value.location.y <= contentHeight
                guard inBounds else {
                    scrubIndex = nil
                    isScrubbing = false
                    return
                }

                // Only a horizontal-dominant drag starts the scrub (a vertical one is
                // left to the scroll view); once scrubbing, keep tracking.
                guard isScrubbing || abs(value.translation.width) > abs(value.translation.height) else { return }

                isScrubbing = true
                let clampedX: CGFloat = min(max(value.location.x, 0), width)
                let slot: CGFloat = width / CGFloat(books.count)
                let index: Int = min(Int(clampedX / slot), books.count - 1)
                if index != scrubIndex { scrubIndex = index }
            }
            .onEnded { _ in
                defer {
                    scrubIndex = nil
                    isScrubbing = false
                }
                guard isScrubbing,
                      let index = scrubIndex,
                      books.indices.contains(index) else { return }
                path.append(NavigationDestination.book(anchor: .item(books[index])))
            }
    }
}
