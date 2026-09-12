//
//  View+applyBackground.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/03/2026.
//
import SwiftUI

extension View {
    /// The screen's own grey, behind a list that no longer paints its own.
    ///
    /// The colour is placed in a background that ignores **every** safe-area region, keyboard
    /// included, and not simply handed to `.background(_:)`. A list under a keyboard has its
    /// safe area cut by the keyboard inset, so a background sized on that shrunken frame leaves
    /// the strip the keyboard occupies — and, for the length of the dismissal animation, the
    /// strip it has just left — belonging to nobody: what shows there is the window's white.
    ///
    /// Only the background overflows. `.ignoresSafeArea(.keyboard)` on the list itself would
    /// slide its rows under the keyboard, which is a worse bug than the one it fixes.
    func applyListBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background {
                DesignSystem.Color.backgroundSecondary.color
                    .ignoresSafeArea(.all)
            }
    }
}
