//
//  ShelfRowView.swift
//  ReCIT_iOS
//
//  One étagère: the watercolour wash, the books (spines or pile), the wooden plank,
//  and the shelf name beneath. A tap on the shelf grows the book nearest the finger
//  (and drops any other one back into place); a second tap on that same book opens it.
//  The shelf's own list is reached by tapping its name.
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
    /// Shared across the carousel, so only one book stands out at a time.
    @Binding var selection: ShelfBookSelection?

    @State private var editing: Bool = false

    /// Books shown on the shelf, newest first, capped so a huge shelf doesn't render
    /// hundreds of spines (the overflow is reachable via the shelf's list).
    private var books: [InventoryItem] {
        Array(shelf.items.sorted { $0.created > $1.created }.prefix(18))
    }

    /// The grown book, when the carousel's selection points at this shelf.
    private var selectedIndex: Int? {
        guard let selection, selection.shelfId == shelf._id else { return nil }
        return selection.index
    }

    private var plankHeight: CGFloat { width * 129.0 / 820.0 }
    private var zoneHeight: CGFloat { width * 9.0 / 16.0 }
    /// Minimal room above the books for a centre-zoomed spine (×1.5) to grow upward
    /// without being clipped by the carousel's scroll bounds.
    private var topRoom: CGFloat { zoneHeight * 0.25 }
    /// How far the wash extends below the plank (kept small); the shelf name sits at
    /// this same distance so the wash isn't cropped.
    private let washBelow: CGFloat = 16

    private var layout: ShelfBooksLayout {
        .init(
            pageCounts: books.map { $0.edition?.numberOfPages },
            width: ShelfBooksView.booksWidth(cardWidth: width),
            zoneHeight: zoneHeight
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            shelfStack
                .padding(.top, topRoom)
            HStack(spacing: .xSmall) {
                Button(shelf.name) { path.append(NavigationDestination.shelf(id: shelf._id)) }
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(1)
                Button("Modifier l'étagère", systemImage: "pencil") { editing = true }
                    .labelStyle(.iconOnly)
                    .font(.footnote)
                    .foregroundStyle(.foregroundSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top, washBelow)
        }
        .frame(width: width)
        .sensoryFeedback(.selection, trigger: selectedIndex)
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
                    layout: layout,
                    selectedIndex: selectedIndex
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
        .contentShape(.rect)
        // Location-based, so a plain Button won't do: the tap has to say which book it
        // landed nearest. The whole card (books zone and plank) is a target.
        .onTapGesture { location in select(at: location) }
    }

    /// Grows the book nearest the tap, or opens it when it is already the grown one.
    private func select(at location: CGPoint) {
        let point: CGPoint = .init(
            x: location.x - ShelfBooksView.horizontalMargin,
            y: location.y
        )
        guard let index = layout.nearestIndex(to: point), books.indices.contains(index) else { return }
        guard index == selectedIndex else {
            selection = .init(shelfId: shelf._id, index: index)
            return
        }
        selection = nil
        path.append(NavigationDestination.book(anchor: .item(books[index])))
    }
}
