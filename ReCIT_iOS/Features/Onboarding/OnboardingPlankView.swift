//
//  OnboardingPlankView.swift
//  ReCIT_iOS
//
//  Onboarding's illustration: the shelf the rest of the app paints — wash and plank, the same
//  two assets — carrying whatever it is given, and nothing when it is given nothing.
//
//  Bare on purpose on the accueil. The inventory is empty by construction when that screen
//  appears, so invented spines would put an étagère on screen that resembles data the user does
//  not have, in the one screen whose whole point is that they do not have it yet. The accueil
//  promises with words; the bilan is what pays, with the user's own covers — see
//  `OnboardingScanTallyIllustrationView`.
//
//  The books are a slot rather than a parameter, and that slot is what keeps the illustration a
//  *composition* of views: a plank, plus books that can be animated one at a time. A flattened
//  image of a full shelf would be cheaper to draw and impossible to animate, which is the whole
//  reason this file exists rather than an asset.
//
//  It borrows `ShelfEmptyStateView`'s composition rather than its type: that view is a card in the
//  bookshelf, sized by the carousel and carrying a paper note, and neither belongs here. What is
//  shared is the paint — the wash spilling the same distance below the plank, at the same opacity
//  — so the plank a user meets first is the plank they keep seeing.
//
//  Every size is a ratio, so nothing has to measure itself here: the band above the plank only has
//  to keep a shelf's proportions, and whatever fills it measures the width it was handed.
//
//  See PRD 0007.
//

import SwiftUI

struct OnboardingPlankView<Books: View>: View {

    /// What stands on the plank. Bottom-aligned in the band, and free to draw above it: a book on
    /// its way down has to come from somewhere, so the band deliberately does not clip.
    private let books: Books

    /// How far the wash spills below the plank, matching the shelf cards so the paint ends where
    /// a reader of this app expects it to.
    private let washBelowPlank: CGFloat = 16
    /// The wash's own weight — the `opacity/surface/plank` token the shelf cards use.
    private let washOpacity: CGFloat = 0.92
    /// The band books stand in, at a shelf card's 16:9 — the same ratio `ShelfCardMetrics` derives
    /// its books zone from, so a book laid out against the measured width lands in it exactly.
    /// Kept at full height even when empty: it is what gives the wash its height and the plank its
    /// place at the bottom.
    private let bookBandAspectRatio: CGFloat = 16.0 / 9.0

    init(@ViewBuilder books: () -> Books) {
        self.books = books()
    }

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
                    // An overlay rather than another stack, so the band's ratio keeps deciding
                    // the height and the books cannot stretch it.
                    .overlay(alignment: .bottom) { books }
                Image("ShelfPlank")
                    .resizable()
                    .scaledToFit()
            }
        }
        // Decoration: the sentence under it says everything it says.
        .accessibilityHidden(true)
    }
}

extension OnboardingPlankView where Books == EmptyView {

    /// The bare plank, for the accueil.
    init() {
        self.init { EmptyView() }
    }
}

#Preview {
    OnboardingPlankView()
        .padding(.horizontal, .large)
}
