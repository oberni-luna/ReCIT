//
//  CoverWallSlotView.swift
//  ReCIT_iOS
//
//  One slot of the wall: a painted jacket, and over it the real cover once it has loaded.
//
//  The painted one is never removed. It is the floor: a cover that fails to load, a cover the
//  feed did not have, a cover still in flight — all three leave a painted book rather than a
//  hole, and the wall never shows its own scaffolding.
//
//  The real cover fades in **on its own delay**, drawn between zero and four hundred
//  milliseconds. All thirty slots revealing together reads as a flash, as if the screen had
//  reloaded; staggered, it reads as the wall coming into focus. The delay is random rather than
//  derived from the slot, so two identical walls do not resolve in the same visible order.
//
//  See PRD 0011.
//

import SwiftUI

struct CoverWallSlotView: View {

    /// The cover to draw here, if the feed had one for this slot.
    let url: URL?

    /// Which painted jacket stands underneath.
    let paintedVariant: Int

    /// The frame the wall reserved, cover art or not.
    let size: CGSize

    /// How long a cover takes to fade in, and the widest delay before it starts.
    private static let fadeDuration: TimeInterval = 0.3
    private static let revealDelayRange: ClosedRange<Int> = 0...400

    @State private var isRevealed: Bool = false

    var body: some View {
        ZStack {
            PaintedCoverView(variant: paintedVariant)

            if let url {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: CoverWallPalette.coverCornerRadius))
                .opacity(isRevealed ? 1 : 0)
            }
        }
        .frame(width: size.width, height: size.height)
        .animation(.easeIn(duration: Self.fadeDuration), value: isRevealed)
        .task(id: url) { await reveal() }
    }

    private func reveal() async {
        guard url != nil else {
            isRevealed = false
            return
        }

        isRevealed = false

        let delay: Int = .random(in: Self.revealDelayRange)
        try? await Task.sleep(for: .milliseconds(delay))

        isRevealed = true
    }
}
