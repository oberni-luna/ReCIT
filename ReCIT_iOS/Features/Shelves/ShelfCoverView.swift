//
//  ShelfCoverView.swift
//  ReCIT_iOS
//
//  A lone book on a shelf, shown face-on with its real cover — prettier than a single spine.
//  Shared by the shelf and by the focus overlay. See ADR 0003 / ADR 0006.
//

import SwiftUI

struct ShelfCoverView: View {
    let item: InventoryItem
    let size: CGSize
    /// Whether to stand in a sheet of parchment until the cover has loaded. The focus overlay
    /// turns it off: the shelf's own cover is still drawn underneath, so a placeholder there
    /// only ever reads as a flash — a pale slab twice the size of the book.
    var showsPlaceholder: Bool = true

    var body: some View {
        CachedAsyncImage(url: item.edition?.image.flatMap { URL(string: $0) }) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            if showsPlaceholder {
                ZStack {
                    RoundedRectangle(cornerRadius: 2).fill(ShelfPalette.parchment)
                    Text(item.edition?.title ?? "")
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
