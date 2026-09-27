//
//  ShelfPaperModifier.swift
//  ReCIT_iOS
//
//  The paper a shelf's writing is on: white, rounded, lifted by a soft shadow and leaning a
//  degree or so, as if applied by hand. Shared by an étagère's name tag (`ShelfLabelView`)
//  and the empty shelf's action tags (`ShelfActionTag`), so the paper, radius, shadow and
//  lean cannot diverge between them. See PRD 0003.
//
//  Padding stays with each caller: a name tag is a single line, an action tag two, and they
//  are not spaced alike.
//

import SwiftUI

struct ShelfPaperModifier: ViewModifier {
    /// What is written on the paper — the lean is derived from it, and from nothing else.
    let text: String

    func body(content: Content) -> some View {
        content
            .background(ShelfPalette.labelPaper, in: RoundedRectangle(cornerRadius: .minimal))
            // The paper is the target, all of it — text, ornaments and padding alike — and
            // only it, so the empty part of the box around it doesn't swallow presses.
            .contentShape(RoundedRectangle(cornerRadius: .minimal))
            // Flattened first, so the shadow is the paper's alone: without it SwiftUI casts one
            // under every glyph and link written on the paper as well.
            .compositingGroup()
            .shadow(.light)
            .rotationEffect(.degrees(ShelfLabelTilt.degrees(for: text)))
    }
}

extension View {
    /// Sets the view on a paper tag leaning by the angle `text` gives it.
    func shelfPaper(text: String) -> some View {
        modifier(ShelfPaperModifier(text: text))
    }
}
