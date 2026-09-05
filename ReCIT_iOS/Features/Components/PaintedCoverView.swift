//
//  PaintedCoverView.swift
//  ReCIT_iOS
//
//  One painted book jacket: a flat tint, a band low on the cover, and two short lines where a
//  title would be. It is what the wall shows before its covers arrive, and what a slot keeps
//  if no cover ever comes.
//
//  Deliberately not `PaintedBookView`: that one paints a *spine* from a sliver of a real
//  cover and needs an `Edition` to do it. This one has no book behind it, and is drawn from an
//  index alone — which is what makes the wall reviewable, since the same size always gives the
//  same wall. See PRD 0011.
//

import SwiftUI

struct PaintedCoverView: View {

    /// Which painted jacket this is. Any integer; the palette cycles.
    let variant: Int

    var body: some View {
        CoverWallPalette.tint(at: variant)
            .overlay(alignment: .leading) { fold }
            .overlay(alignment: .topLeading) { titleLines }
            .overlay(alignment: .bottom) { band }
            .clipShape(.rect(cornerRadius: CoverWallPalette.coverCornerRadius))
            .overlay {
                // A hairline edge. Without it a flat tint under a veil reads as a pane of
                // frosted glass; with it, as an object with a border, which is what a book is.
                RoundedRectangle(cornerRadius: CoverWallPalette.coverCornerRadius)
                    .strokeBorder(CoverWallPalette.paintedEdge, lineWidth: 1)
            }
    }

    /// The darker strip down the binding edge — the fold of a jacket over a spine. It is what
    /// tells the eye which way the book faces.
    private var fold: some View {
        GeometryReader { proxy in
            CoverWallPalette.paintedFold
                .frame(width: max(2, proxy.size.width * 0.07))
        }
    }

    /// The two lines standing in for a title, set in from the top-left corner as a jacket
    /// would set them. Sized as fractions of the cover, so they hold at any column width.
    private var titleLines: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: proxy.size.height * 0.04) {
                line(width: proxy.size.width * 0.6, in: proxy.size)

                line(width: proxy.size.width * 0.42, in: proxy.size)
            }
            .padding(.leading, proxy.size.width * 0.13)
            .padding(.top, proxy.size.height * 0.15)
        }
    }

    private func line(width: CGFloat, in size: CGSize) -> some View {
        CoverWallPalette.paintedTitle
            .frame(width: width, height: max(1, size.height * 0.022))
    }

    /// The band across the lower third, which is what makes a rectangle read as a jacket
    /// rather than as a coloured tile.
    private var band: some View {
        GeometryReader { proxy in
            CoverWallPalette.paintedBand
                .frame(height: max(2, proxy.size.height * 0.03))
                .offset(y: proxy.size.height * 0.64)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(0..<6, id: \.self) { variant in
            PaintedCoverView(variant: variant)
                .frame(width: 88, height: 132)
        }
    }
    .padding()
    .background(.black)
}
