//
//  ShelfRowView.swift
//  ReCIT_iOS
//
//  One étagère: the watercolour wash, the books (spines or pile), the wooden plank,
//  and the shelf name beneath. Tap opens the shelf's list; a ~0.2s press then a slide
//  scrubs the books (zoom + haptic) and, on release, opens the book under the finger.
//  A plain swipe is left to the carousel scroll.
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
    /// Shared with the carousel so it can disable its scroll while a scrub is active.
    @Binding var scrubbing: Bool

    @State private var scrubIndex: Int?
    @State private var editing: Bool = false

    /// Books shown on the shelf, newest first, capped so a huge shelf doesn't render
    /// hundreds of spines (the overflow is reachable via the shelf's list).
    private var books: [InventoryItem] {
        Array(shelf.items.sorted { $0.created > $1.created }.prefix(18))
    }

    private var plankHeight: CGFloat { width * 129.0 / 820.0 }
    private var zoneHeight: CGFloat { width * 9.0 / 16.0 }
    /// Width the books actually occupy (card minus the horizontal margin on each side).
    private var booksWidth: CGFloat { max(width - ShelfBooksView.horizontalMargin * 2, 0) }
    /// Minimal room above the books for a centre-zoomed spine (×1.5) to grow upward
    /// without being clipped by the carousel's scroll bounds.
    private var topRoom: CGFloat { zoneHeight * 0.25 }
    /// How far the wash extends below the plank (kept small); the shelf name sits at
    /// this same distance so the wash isn't cropped.
    private let washBelow: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            shelfStack
                .padding(.top, topRoom)
            HStack(spacing: .xSmall) {
                Text(shelf.name)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(1)
                Button("Modifier l'étagère", systemImage: "pencil") { editing = true }
                    .labelStyle(.iconOnly)
                    .font(.footnote)
                    .foregroundStyle(.foregroundSecondary)
            }
            .padding(.top, washBelow)
        }
        .frame(width: width)
        // Taps on the shelf open its list — handled solely by the scrub overlay, so a
        // single handler (no card-level tap) avoids the double navigation push.
        .sensoryFeedback(.selection, trigger: scrubIndex)
        .sheet(isPresented: $editing) { ShelfFormView(shelf: shelf) }
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
                .offset(y: washBelow)
                .opacity(0.92)
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                ShelfBooksView(
                    books: books,
                    width: width,
                    zoneHeight: zoneHeight,
                    scrubIndex: scrubIndex
                )
                // Books always render in FRONT of the plank so they sit on top of the
                // shelf (and a zoomed book stays above it, never behind/under).
                .zIndex(1)
                Image("ShelfPlank")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: zoneHeight + plankHeight)
        // Scrub overlay covers exactly the books zone (top band, inset by the margin).
        .overlay(alignment: .top) {
            ScrubGestureView(
                onTap: { path.append(NavigationDestination.shelf(id: shelf._id)) },
                onScrubBegan: { scrubbing = true },
                onScrubChanged: { location in
                    // Overlay spans the full card width; books start at the margin.
                    scrubIndex = ScrubMapping.index(
                        x: location.x - ShelfBooksView.horizontalMargin,
                        y: location.y,
                        width: booksWidth,
                        height: zoneHeight,
                        count: books.count
                    )
                },
                onScrubEnded: { _, cancelled in
                    defer {
                        scrubbing = false
                        scrubIndex = nil
                    }
                    guard cancelled == false,
                          let index = scrubIndex,
                          books.indices.contains(index) else { return }
                    path.append(NavigationDestination.book(anchor: .item(books[index])))
                }
            )
            .frame(width: width, height: zoneHeight + plankHeight)
        }
    }
}
