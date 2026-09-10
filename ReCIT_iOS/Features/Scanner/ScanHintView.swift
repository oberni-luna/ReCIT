//
//  ScanHintView.swift
//  ReCIT_iOS
//
//  What the bottom of the scanner says when it has nothing else to say. Before this, `.idle`
//  was a live camera feed and nothing else: a full-screen mode with no instruction, where the
//  only clue about what to point the phone at was the feature's name in the screen the user
//  came from. Someone who opens the scanner without knowing it reads barcodes aims at the
//  cover, waits, and concludes the camera is broken.
//
//  It takes the *exact* place of `ScanResultRowView` — same origin, same scrim, same
//  horizontal band — so a book arriving swaps one block for another instead of pushing the
//  screen around. That is the whole design decision: the hint is not a banner that appears
//  somewhere and has to be dismissed, it is the empty state of a slot that is already there.
//
//  Colours are `ScanOverlayPalette`'s for the same reason the row's are: this floats on a
//  live camera image, which is dark and unpredictable whatever the user's appearance setting.
//
//  See feature 0007, and the `S1 · Repère · Texte sur voile` frame in the Figma file.
//

import SwiftUI

struct ScanHintView: View {
    var body: some View {
        VStack(spacing: .sMedium) {
            Image(systemName: "barcode.viewfinder")
                .font(.title)
                .foregroundStyle(ScanOverlayPalette.tint)

            Text("scanner.hint")
                .textStyle(.content300)
                .foregroundStyle(ScanOverlayPalette.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .xLarge)
        .padding(.vertical, .small)
    }
}
