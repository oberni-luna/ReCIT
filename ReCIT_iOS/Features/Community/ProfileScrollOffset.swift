//
//  ProfileScrollOffset.swift
//  ReCIT_iOS
//
//  Where a reader's profile page is scrolled to, counted from rest — written at every frame of
//  a scroll, and read by the folding header alone. Held in an object rather than in the
//  screen's state so that a scroll redraws the header and nothing else: as `@State` of the
//  screen, every frame re-evaluated the whole page, books included, and the header stuttered
//  as it unfolded.
//

import Observation
import CoreGraphics

@MainActor
@Observable
final class ProfileScrollOffset {
    var value: CGFloat = 0

    /// Exactly at rest — not folding, and not pulled down past the top either.
    var isAtRest: Bool {
        abs(value) < 0.5
    }
}
