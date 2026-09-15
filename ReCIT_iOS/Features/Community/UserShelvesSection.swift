//
//  UserShelvesSection.swift
//  ReCIT_iOS
//
//  The étagères a reader shares, on their profile: the same snapping carousel as my own
//  inventory, between the header card and their books. A friend who has arranged their
//  library is telling you something about it, and until now the app kept it to itself.
//
//  `ShelfRowView` is reused untouched, and that is the point: it carries no editing
//  affordance at all. Pressing a book grows it and lifting opens it; pressing the paper
//  label opens the étagère. Everything that writes — renaming, deleting, filing a book —
//  lives either in the header's "Ajouter" (which this section does not have) or in
//  `ShelfDetailView`'s navigation bar (which stands down for a shelf that is not mine).
//
//  **Posed on nothing.** The rows are transparent and their insets are dropped, so the
//  carousel runs edge to edge over the screen's own background rather than sitting on the
//  darker card the header and the books sit on. It is the one place on this screen where
//  the content is not in a box, and that is deliberate: a shelf is already an object.
//
//  The width is measured rather than guessed. `ShelfRowView` takes an explicit width
//  because a card that measures itself inside a `List` sets off the `UICollectionView`
//  update loop of ADR 0003, and a `GeometryReader` in a list row has no intrinsic height
//  to give. So the horizontal `ScrollView` — which fills the row either way — reports its
//  own width, and the cards are drawn once it has.
//
//  See issue 0092.
//

import SwiftUI
import SwiftData

struct UserShelvesSection: View {
    let user: User
    @Binding var path: NavigationPath

    @Query private var shelves: [Shelf]

    /// Read for one thing: freezing both scroll views while a book is being picked, so the
    /// slide moves the selection instead of the page. Same rule as the inventory's carousel.
    @Environment(ShelfFocusModel.self) private var focus

    /// The row's width, published by the scroll view that fills it. Zero until the first
    /// layout pass, which is what `hasWidth` reads.
    @State private var availableWidth: CGFloat = 0

    /// Same proportions as the inventory's own carousel, so an étagère is the same object
    /// on both screens: the card takes most of the width and the next one peeks.
    private let widthRatio: CGFloat = 0.86
    private let horizontalPadding: CGFloat = 12
    private let gutter: CGFloat = 14

    private var cardWidth: CGFloat { availableWidth * widthRatio }
    private var hasWidth: Bool { availableWidth > 0 }

    init(user: User, path: Binding<NavigationPath>) {
        self.user = user
        self._path = path

        let ownerId: String = user._id
        _shelves = Query(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.name,
            order: .forward
        )
    }

    var body: some View {
        // No étagère shared, no band — header included. An empty card would be worse than
        // nothing here: both of the ones the inventory can show run an errand of mine
        // (scanning books in, arranging them), and neither is anything to ask of someone
        // else's library.
        if shelves.isEmpty == false {
            Section {
                carousel
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } header: {
                Text("user.shelves.header \(user.username)")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: gutter) {
                if hasWidth {
                    ForEach(shelves) { shelf in
                        ShelfRowView(shelf: shelf, width: cardWidth, path: $path)
                            .frame(width: cardWidth)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, horizontalPadding)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollDisabled(focus.isArmed)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            availableWidth = width
        }
    }
}
