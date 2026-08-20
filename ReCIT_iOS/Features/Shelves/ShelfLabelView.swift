//
//  ShelfLabelView.swift
//  ReCIT_iOS
//
//  The paper tag stuck onto a plank's bottom edge: white, rounded, lifted by a soft
//  shadow and leaning a degree or so, as if applied by hand. One view for both the
//  étagère's name (with a chevron, one line) and the empty state's invitation (no
//  chevron, two centred lines), so the paper, radius, shadow, padding and lean cannot
//  diverge between them. See PRD 0003.
//
//  The chevron sits *outside* the truncating text, so a name too long for the card loses
//  its tail to an ellipsis and never its affordance. The width is whatever the text needs,
//  up to `maxWidth` — the tag stays a tag rather than growing into a banner.
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
    var showsChevron: Bool = true
    var lineLimit: Int = 1
    /// How the lines sit relative to each other when the text wraps.
    var textAlignment: TextAlignment = .leading
    /// Where the paper sits within `maxWidth`. Separate from `textAlignment` because the
    /// two genuinely differ: the empty state's tag is centred on the card while its own
    /// two lines stay left-aligned to each other.
    var placement: Alignment = .center

    var body: some View {
        HStack(spacing: .xSmall) {
            Text(text)
                .textStyle(.content300)
                .foregroundStyle(ShelfPalette.labelInk)
                .lineLimit(lineLimit)
                .multilineTextAlignment(textAlignment)

            if showsChevron {
                // Drawn by hand: a `NavigationLink` outside a `List` supplies no disclosure
                // indicator, so there is no framework glyph to inherit here.
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
        .padding(.horizontal, .small)
        .padding(.vertical, .xSmall)
        .background(ShelfPalette.labelPaper, in: RoundedRectangle(cornerRadius: .minimal))
        // The paper is the target, all of it — text, chevron and padding alike — and only
        // it, so the empty part of the box below doesn't swallow presses meant for the shelf.
        .contentShape(RoundedRectangle(cornerRadius: .minimal))
        .shadow(.light)
        .rotationEffect(.degrees(ShelfLabelTilt.degrees(for: text)))
        // The paper hugs its text (the background is applied first); this box only caps how
        // wide it may get and decides where on the card it sits.
        .frame(maxWidth: maxWidth, alignment: placement)
    }
}
