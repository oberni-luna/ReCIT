//
//  OnboardingPlankView.swift
//  ReCIT_iOS
//
//  Onboarding's illustration: the shelf the rest of the app paints — wash and plank, the same
//  two assets — carrying nothing at all.
//
//  Bare on purpose on the accueil. The inventory is empty by construction when that screen
//  appears, so invented spines would put an étagère on screen that resembles data the user does
//  not have, in the one screen whose whole point is that they do not have it yet. The accueil
//  promises with words; the bilan is what pays, with the user's own covers.
//
//  The bilan borrows it bare for now, which is the one thing that is provisional here: those
//  covers, and the way they settle onto the plank one by one, arrive with their own slice.
//
//  It borrows `ShelfEmptyStateView`'s composition rather than its type: that view is a card in the
//  bookshelf, sized by the carousel and carrying a paper note, and neither belongs here. What is
//  shared is the paint — the wash spilling the same distance below the plank, at the same opacity
//  — so the plank a user meets first is the plank they keep seeing.
//
//  Every size is a ratio, so nothing has to measure itself: with no books to lay out, the band
//  above the plank only has to keep a shelf's proportions.
//
//  See PRD 0007.
//

import SwiftUI

struct OnboardingPlankView: View {

    /// How far the wash spills below the plank, matching the shelf cards so the paint ends where
    /// a reader of this app expects it to.
    private let washBelowPlank: CGFloat = 16
    /// The wash's own weight — the `opacity/surface/plank` token the shelf cards use.
    private let washOpacity: CGFloat = 0.92
    /// The band books would stand in, at a shelf card's 16:9. Empty here, and kept anyway: it is
    /// what gives the wash its height and the plank its place at the bottom.
    private let bookBandAspectRatio: CGFloat = 16.0 / 9.0

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("ShelfWash")
                .resizable()
                .scaledToFit()
                .offset(y: washBelowPlank)
                .opacity(washOpacity)
            VStack(spacing: .zero) {
                Color.clear
                    .aspectRatio(bookBandAspectRatio, contentMode: .fit)
                Image("ShelfPlank")
                    .resizable()
                    .scaledToFit()
            }
        }
        // Decoration: the sentence under it says everything it says.
        .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingPlankView()
        .padding(.horizontal, .large)
}
