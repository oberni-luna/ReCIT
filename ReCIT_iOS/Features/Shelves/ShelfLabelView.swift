//
//  ShelfLabelView.swift
//  ReCIT_iOS
//
//  The paper tag stuck onto a plank's bottom edge: white, rounded, lifted by a soft
//  shadow and leaning a degree or so, as if applied by hand. One view for both the
//  étagère's name and the empty state's invitation, so the paper, radius, shadow, padding
//  and lean cannot diverge between them. See PRD 0003.
//
//  What differs is the `Kind`: a name is set between two bullets, the way a shelf's paper
//  tag is written by hand; a note carries a chevron, because pressing it leads somewhere.
//
//  Both ornaments sit *outside* the truncating text, so a name too long for the card loses
//  its tail to an ellipsis and never its closing bullet. The width is whatever the text
//  needs, up to `maxWidth` — the tag stays a tag rather than growing into a banner.
//
//  It draws nothing of its own above the focus veil: the label is part of the card and
//  dims with it while a book is being pressed. See ADR 0006.
//

import SwiftUI

struct ShelfLabelView: View {

    /// What the paper says, and therefore what it wears.
    enum Kind {
        /// An étagère's name, set between bullets.
        case name
        /// The empty state's invitation, which leads somewhere and says so.
        case note
    }

    let text: String
    /// The widest the paper may get — the card minus the books' margins, so a tag never
    /// overhangs the shelf it is stuck to.
    let maxWidth: CGFloat
    var kind: Kind = .name
    var lineLimit: Int = 1
    /// How the lines sit relative to each other when the text wraps.
    var textAlignment: TextAlignment = .leading
    /// Where the paper sits within `maxWidth`. Separate from `textAlignment` because the
    /// two genuinely differ: the empty state's tag is centred on the card while its own
    /// two lines stay left-aligned to each other.
    var placement: Alignment = .center

    var body: some View {
        HStack(spacing: .xSmall) {
            if kind == .name {
                bullet
            }

            Text(text)
                .textStyle(.content300)
                .foregroundStyle(ShelfPalette.labelInk)
                .lineLimit(lineLimit)
                .multilineTextAlignment(textAlignment)

            if kind == .name {
                bullet
            }

            if kind == .note {
                // Drawn by hand: a `NavigationLink` outside a `List` supplies no disclosure
                // indicator, so there is no framework glyph to inherit here.
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(ShelfPalette.labelInkSecondary)
            }
        }
        .padding(.horizontal, .small)
        .padding(.vertical, .xSmall)
        .background(ShelfPalette.labelPaper, in: RoundedRectangle(cornerRadius: .minimal))
        // The paper is the target, all of it — text, ornaments and padding alike — and only
        // it, so the empty part of the box below doesn't swallow presses meant for the shelf.
        .contentShape(RoundedRectangle(cornerRadius: .minimal))
        .shadow(.light)
        .rotationEffect(.degrees(ShelfLabelTilt.degrees(for: text)))
        // The paper hugs its text (the background is applied first); this box only caps how
        // wide it may get and decides where on the card it sits.
        .frame(maxWidth: maxWidth, alignment: placement)
    }

    /// Ornament, not text: VoiceOver reads the étagère's name, not the paper it is written on.
    private var bullet: some View {
        Text(verbatim: "•")
            .textStyle(.content300)
            .foregroundStyle(ShelfPalette.labelInk)
            .accessibilityHidden(true)
    }
}
