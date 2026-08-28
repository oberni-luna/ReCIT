//
//  OnboardingScreenLayout.swift
//  ReCIT_iOS
//
//  The skeleton both onboarding screens stand on: an illustration held off the top and the
//  bottom of the screen, a title and a sentence under it, and the answers at the foot.
//
//  It exists because the two screens are the same screen twice over — the design captures the
//  bilan as "même squelette que C1, même géométrie de bouton" — and a second copy of these
//  paddings is how the accueil and the bilan come to sit a few points apart on the same phone
//  for no reason anyone can name.
//
//  The illustration and the answers are slots rather than parameters. Both are already known to
//  change: the bilan's plank gains the user's own covers, and a phone that cannot arrange books
//  shows a reason where the call to action would be. Neither of those is a variation of a shared
//  shape, so neither is described here.
//
//  Title and message arrive as `Text` rather than as keys: the bilan's title carries a count
//  into a catalogue plural rule, which a plain key cannot express.
//
//  Nothing here is allowed to push the answers off the bottom of the screen. This is a
//  full-screen cover with no navigation bar, so those buttons are the only way out of it, and at
//  the accessibility text sizes — or on a 667pt phone — the illustration and the copy used to
//  squeeze them past the edge. So the screen has three arrangements and takes the first that
//  fits: standing as it always has, then the copy scrolling under pinned answers, then the whole
//  page scrolling when even the answers are taller than the phone.
//
//  See PRD 0007, designs C1 and C2, and issue 0060 for the sizes that broke it.
//

import SwiftUI

struct OnboardingScreenLayout<Illustration: View, Actions: View>: View {
    private let title: Text
    private let message: Text
    private let illustration: Illustration
    private let actions: Actions

    init(
        title: Text,
        message: Text,
        @ViewBuilder illustration: () -> Illustration,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.illustration = illustration()
        self.actions = actions()
    }

    var body: some View {
        // Three arrangements, in the order they are worth having, and `ViewThatFits` takes the
        // first that the phone can hold.
        ViewThatFits(in: .vertical) {
            // 1. Everything stands, as it always has. At the text sizes this screen was drawn
            //    for there is no scroll view in the tree at all — nothing scrolls that did not
            //    scroll before, nothing bounces, and the content's two spacers keep doing the
            //    centring themselves. A scroll view could not have kept that on its own: it does
            //    not stretch content shorter than its viewport, and pinning the content to the
            //    container's height instead would clip the copy at exactly the sizes this exists
            //    for, trading one unreachable answer for one unreadable sentence.
            VStack(spacing: .zero) {
                content

                actionsBar
            }

            // 2. The copy scrolls, the answers hold the foot of the screen. They are the only
            //    way out of a full-screen cover, so they are worth an inset of their own for as
            //    long as they leave the copy somewhere to be. The scroll view's ideal height is
            //    nothing, which is what makes this arrangement measure as the answers alone:
            //    it is chosen exactly when they fit on their own.
            ScrollView {
                content
            }
            .frame(idealHeight: .zero, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                actionsBar
            }

            // 3. Everything scrolls. The bilan's unavailable ending puts a whole paragraph where
            //    a button usually goes, and past the accessibility sizes that block alone is
            //    taller than the phone: pinned, it would eat the screen and truncate its own
            //    reason. Scrolled, every word of it is readable and both answers are reached the
            //    ordinary way.
            ScrollView {
                VStack(spacing: .zero) {
                    content

                    actionsBar
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
    }

    /// The illustration and the copy. Named here rather than written out three times, once per
    /// arrangement — the three differ in what carries them, never in what they carry.
    private var content: OnboardingScreenContent<Illustration> {
        .init(
            title: title,
            message: message,
            illustration: illustration
        )
    }

    /// The answers, with the paddings the standing stack used to hand them: a `.large` above,
    /// where the stack's spacing was, and a `.large` below, where its bottom padding was. So the
    /// screen at default text sizes is the screen that was there before, to the point. The
    /// background is the screen's own, invisible until copy scrolls under it.
    private var actionsBar: some View {
        actions
            .padding(.horizontal, .medium)
            .padding(.vertical, .large)
            .background(.backgroundDefault)
    }
}

#Preview {
    OnboardingScreenLayout(
        title: Text(verbatim: "Vos livres, sur vos étagères"),
        message: Text(verbatim: "Scannez les codes-barres à la chaîne.")
    ) {
        OnboardingPlankView()
    } actions: {
        OnboardingActions(primaryTitle: "onboarding.welcome.scan", onPrimary: {}, onLater: {})
    }
}
