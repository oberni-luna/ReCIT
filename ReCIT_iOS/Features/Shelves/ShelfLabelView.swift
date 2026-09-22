//
//  ShelfLabelView.swift
//  ReCIT_iOS
//
//  The paper tag stuck onto a plank's bottom edge, carrying an étagère's name set between
//  two bullets, the way a shelf's tag is written by hand. The paper itself — white, rounded,
//  shadowed, leaning — is `ShelfPaperModifier`, shared with the empty shelf's action tags so
//  the two cannot diverge. See PRD 0003.
//
//  The bullets sit *outside* the truncating text, so a name too long for the card loses its
//  tail to an ellipsis and never its closing bullet. The width is whatever the text needs, up
//  to `maxWidth` — the tag stays a tag rather than growing into a banner.
//
//  It used to carry the empty state's note too, with a chevron in place of the bullets. The
//  empty shelf now carries a sentence and action tags of its own (`ShelfActionTag`), so this
//  view is back to naming shelves only.
//
//  It draws nothing of its own above the focus veil: the label is part of the card and
//  dims with it while a book is being pressed. See ADR 0006.
//

import SwiftUI

struct ShelfLabelView: View {
    let text: String
    /// The widest the paper may get — the card minus the books' margins, so a tag never
    /// overhangs the shelf it is stuck to.
    let maxWidth: CGFloat

    var body: some View {
        HStack(spacing: .xSmall) {
            bullet

            Text(text)
                .textStyle(.content300)
                .foregroundStyle(ShelfPalette.labelInk)
                .lineLimit(1)

            bullet
        }
        .padding(.horizontal, .small)
        .padding(.vertical, .xSmall)
        .shelfPaper(text: text)
        // The paper hugs its text (the background is applied first); this box only caps how
        // wide it may get and centres it on the card.
        .frame(maxWidth: maxWidth)
    }

    /// Ornament, not text: VoiceOver reads the étagère's name, not the paper it is written on.
    private var bullet: some View {
        Text(verbatim: "•")
            .textStyle(.content300)
            .foregroundStyle(ShelfPalette.labelInk)
            .accessibilityHidden(true)
    }
}
