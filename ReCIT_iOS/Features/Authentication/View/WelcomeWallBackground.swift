//
//  WelcomeWallBackground.swift
//  ReCIT_iOS
//
//  The welcome screen's ground: the wall of covers, and the green sheet that makes text
//  legible over it.
//
//  The veil is not a flat scrim. It is dense at the very top, where the status bar's own
//  glyphs have to read over whatever cover happens to be passing; it thins out through the
//  upper third, where the wall is the picture; and it closes to opaque over the bottom third,
//  where the name, the sentence and the doors sit. A single opacity cannot do those three jobs —
//  pick one that saves the text and the wall disappears, pick one that saves the wall and the
//  text sits on a book jacket.
//
//  The five stops are the mockup's (`265:7532`). They were briefly denser in the middle, back
//  when the copy was centred on the screen and had to be read over the covers; the copy moving
//  to the floor gave that density back to the wall.
//
//  The colour is `color/green/900`, taken as a primitive rather than through a semantic token
//  on purpose: this screen is dark in both system appearances (`AuthFlowView` pins the
//  appearance while the welcome screen is the root), so a mode-aware background would invert
//  under a wall that does not. Same argument as `ShelfPalette`'s paper and ink.
//
//  See PRD 0011 and the `B3` frame of the Figma library (`265:7532`).
//

import SwiftUI

struct WelcomeWallBackground: View {

    /// The covers to draw, as inventaire.io image paths, and where they resolve. Empty is a
    /// valid wall: it is painted instead.
    var coverPaths: [String] = []
    var baseUrl: String = ""

    private static let veilColor: Color = .init("color/green/900")

    /// The sheet over the whole screen. Stops read top to bottom.
    private static let veil: LinearGradient = .init(
        stops: [
            .init(color: veilColor.opacity(0.92), location: 0),
            .init(color: veilColor.opacity(0.6), location: 0.1),
            .init(color: veilColor.opacity(0.74), location: 0.38),
            .init(color: veilColor.opacity(0.96), location: 0.58),
            .init(color: veilColor, location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            // The ground the gutters between covers show. Deep green rather than the window's
            // own background: eight points of black between every two covers reads as a grid
            // of tiles, eight points of green reads as shadow between books.
            Self.veilColor

            CoverWallView(coverPaths: coverPaths, baseUrl: baseUrl)

            Self.veil
        }
        .ignoresSafeArea()
    }
}

#Preview {
    WelcomeWallBackground()
}
