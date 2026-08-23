//
//  ShelfCoverView.swift
//  ReCIT_iOS
//
//  A book shown face-on with its real cover, in a frame decided before the image exists.
//  Shared by the shelf, by the focus overlay, by the onboarding plank and by the sorting
//  surface's piles — which is why it moved out of `Features/Shelves/` and why it takes
//  **values** rather than an `InventoryItem`: the sorting surface holds a frozen snapshot of
//  value types and has no model objects to hand over. See ADR 0003 / ADR 0006 / PRD 0009.
//
//  One renderer, so one shadow. Four screens drawing a cover with four slightly different
//  shadows is exactly the drift a design system exists to prevent, and the shadow is kept in
//  dark mode: on a pile it falls on the covers behind, where it still reads.
//
//  The frame is passed in, never measured: every size on a shelf is derived from the card's
//  width, and a self-measuring cover in a `List` once caused a `UICollectionView` update
//  loop (ADR 0003). It also means a cover arriving late costs nothing — `CachedAsyncImage`
//  cross-fades inside a frame that is already claimed.
//

import SwiftUI

struct ShelfCoverView: View {
    /// The cover's absolute URL, as the store or the snapshot holds it.
    let imageUrl: String?
    /// The book's title, shown on the parchment placeholder while the image loads.
    let title: String
    let size: CGSize
    /// How the artwork meets its frame. `.fit` keeps a cover whole with air around it — right on
    /// a shelf, where the book's proportions are the point. `.fill` crops it to the frame
    /// instead, which the sorting surface wants: a fitted cover leaves transparent bands that a
    /// drag lifts along with the artwork.
    var contentMode: ContentMode = .fit
    /// Whether to stand in a sheet of parchment until the cover has loaded. The focus overlay
    /// turns it off: the shelf's own cover is still drawn underneath, so a placeholder there
    /// only ever reads as a flash — a pale slab twice the size of the book.
    var showsPlaceholder: Bool = true

    var body: some View {
        CachedAsyncImage(url: imageUrl.flatMap { URL(string: $0) }) { image in
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } placeholder: {
            if showsPlaceholder {
                ZStack {
                    RoundedRectangle(cornerRadius: 2).fill(ShelfPalette.parchment)
                    Text(title)
                        .textStyle(.caption200)
                        .foregroundStyle(.foregroundSecondary)
                        .multilineTextAlignment(.center)
                        .padding(4)
                }
            } else {
                Color.clear
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 2))
        .shadow(color: .black.opacity(0.22), radius: 3, x: 1, y: 2)
    }
}

extension ShelfCoverView {

    /// A cover for a copy the store holds. The convenience the shelf screens use, so a call
    /// site that has an item does not have to unwrap its edition twice.
    init(
        item: InventoryItem,
        size: CGSize,
        contentMode: ContentMode = .fit,
        showsPlaceholder: Bool = true
    ) {
        self.init(
            imageUrl: item.edition?.image,
            title: item.edition?.title ?? "",
            size: size,
            contentMode: contentMode,
            showsPlaceholder: showsPlaceholder
        )
    }
}
