//
//  CoverWallView.swift
//  ReCIT_iOS
//
//  A wall of book covers, tall enough to fill whatever it is given, drawn from
//  `CoverWallGeometry`. A thin renderer over that module: it reads the container's size, asks
//  where each cover sits at a given instant, and puts it there. All the arithmetic — tiling,
//  the seamless loop, which cover goes in which slot — is in the module and is tested there.
//
//  Written to be reused. Its column count, its instant and its pace are parameters, because
//  the empty-inventory screen wants the same wall behind a light veil and at a standstill.
//  What it deliberately does not own is the veil: a wall is legible under a dark green sheet on
//  the welcome screen and under a pale one over an inventory, and that is the caller's call.
//
//  The wall is invisible to VoiceOver. Thirty-odd unnamed images between the top of the screen
//  and the first button is not a screen anyone can use, and the wall says nothing that the
//  pitch does not already say out loud.
//
//  See PRD 0011.
//

import SwiftUI

struct CoverWallView: View {

    /// How many columns to lay the wall on.
    var columnCount: Int = CoverWallGeometry.defaultColumnCount

    /// The instant to draw, in seconds since the wall started moving. A fixed value draws a
    /// still wall — which is what the screen shows when the system asks for less motion.
    var elapsed: TimeInterval = 0

    /// Scales every column's speed at once. `0` freezes the wall where its phases put it.
    var speedScale: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let geometry: CoverWallGeometry = .init(size: proxy.size, columnCount: columnCount)

            ZStack(alignment: .topLeading) {
                ForEach(0..<geometry.columnCount, id: \.self) { column in
                    ForEach(0..<geometry.rowCount, id: \.self) { row in
                        cover(row: row, column: column, geometry: geometry)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
        // Decoration, and nothing else: it takes no touch and answers no screen reader. Thirty
        // unnamed images between the top of the screen and the first button is not a screen
        // anyone can use, and a wall that could swallow a tap would be a wall that costs
        // someone their sign-in.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One slot of the wall. A painted jacket for now; the covers of real books land here with
    /// issue 0070, in the same frame and at the same place.
    private func cover(row: Int, column: Int, geometry: CoverWallGeometry) -> some View {
        PaintedCoverView(
            variant: geometry.paintedIndex(
                ofRow: row,
                inColumn: column,
                variantCount: CoverWallPalette.paintedTints.count
            )
        )
        .frame(width: geometry.coverWidth, height: geometry.coverHeight)
        .shadow(color: .black.opacity(0.16), radius: 1.5, x: 0, y: 1.5)
        .offset(
            x: geometry.x(ofColumn: column),
            y: geometry.y(ofRow: row, inColumn: column, at: elapsed, speedScale: speedScale)
        )
    }
}

#Preview {
    CoverWallView()
        .background(.black)
}
