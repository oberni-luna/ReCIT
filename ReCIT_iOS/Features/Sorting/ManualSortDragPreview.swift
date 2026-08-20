//
//  ManualSortDragPreview.swift
//  ReCIT_iOS
//
//  The book while it is in the air: the same row, on a card of its own.
//
//  Given explicitly rather than left to the default, because a list row has no
//  background of its own — dragged as-is it would fly as floating text over whatever
//  it passes. The card is what the design draws: `background/default` at
//  `radius/medium`.
//
//  **No shadow is applied here.** The mockup lifts the row with `Shadow/Pressed`, a
//  Figma effect style that no Swift symbol backs (`DesignSystem.Shadow` has one case,
//  `light`, and it is the shelf label's paper). Rather than invent a token for a
//  levitation the system has never needed, the lift is left to the platform, which
//  shadows a drag preview itself — so the drawn intent is met and nothing is invented.
//
//  See PRD 0008 and docs/design-system/figma-library.md.
//

import SwiftUI

struct ManualSortDragPreview: View {

    let book: AutoSortBook
    let showsGenre: Bool

    var body: some View {
        AutoSortBookRow(
            book: book,
            showsGenre: showsGenre,
            showsDragHandle: true
        )
        .padding(.all, .sMedium)
        .background(.backgroundDefault)
        .clipShape(.rect(cornerRadius: .medium))
    }
}
