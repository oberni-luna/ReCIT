//
//  WelcomeView.swift
//  ReCIT_iOS
//
//  What the app is for, said before anyone is asked who they are: the name, a tagline, the three
//  uses in three rows, and the two doors.
//
//  **The actions may never leave the screen.** They are the reason most people opened the app,
//  and on a 667pt phone at an accessibility text size the pitch alone is taller than the display.
//  So the screen has three arrangements and takes the first that fits — standing, then the pitch
//  scrolling under a pinned bar, then everything scrolling when even the bar is taller than the
//  phone. The idea is `OnboardingScreenLayout`'s; the type is not reused, because that one holds
//  an illustration slot this screen deliberately does not want (the three glyphs are the
//  illustration) and exists to say that its two screens are one screen twice over. This is a
//  third screen, not a third copy.
//
//  The inventaire.io footnote sits **in the pinned bar**, under the buttons, rather than at the
//  end of the pitch. It qualifies "Créer un compte" — the account being created is not this
//  app's — and a disclosure that scrolls away from the button it qualifies is a disclosure that
//  was not made.
//
//  Behind all three arrangements: a wall of book covers under a green veil (PRD 0011). The
//  screen is therefore dark **in both system appearances** — `AuthFlowView` pins the appearance
//  while this screen is the stack's root, which is also what turns the status bar's glyphs
//  white. Every colour here still comes from a token; they simply resolve to their dark
//  values. The one thing that had to change is the actions bar's background: an opaque
//  `backgroundDefault` under the buttons would punch a black rectangle through the wall, so it
//  carries the veil's own gradient instead.
//
//  See PRD 0010, PRD 0011, issue 0056, and the `Accueil` frames in the Figma library.
//

import SwiftUI

struct WelcomeView: View {
    let coverWall: CoverWallModel
    let onSignIn: () -> Void
    let onCreateAccount: () -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            // 1. Everything stands. At the sizes this screen was drawn for there is no scroll
            //    view in the tree at all: nothing bounces, and the pitch's spacers do the
            //    centring themselves.
            VStack(spacing: .zero) {
                pitch

                actionsBar
            }

            // 2. The pitch scrolls, the doors hold the foot of the screen. The scroll view's
            //    ideal height is nothing, which is what makes this arrangement measure as the
            //    bar alone — so it is chosen exactly when the bar fits on its own.
            ScrollView {
                pitch
            }
            .frame(idealHeight: .zero, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                actionsBar
            }

            // 3. Everything scrolls. Past the largest accessibility sizes two capsule buttons
            //    and a footnote are themselves taller than a small phone; pinned, they would eat
            //    the screen and truncate their own text.
            ScrollView {
                VStack(spacing: .zero) {
                    pitch

                    actionsBar
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            WelcomeWallBackground(
                coverPaths: coverWall.coverPaths,
                baseUrl: coverWall.baseUrl
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        // Every time the screen comes up, including on the way back from signing out: the wall
        // shows what the community added last, and "last" moves.
        .task { await coverWall.refresh() }
    }

    /// The name, the tagline and the three uses. Written once and carried by all three
    /// arrangements — a second copy of these paddings is how the same screen comes to sit a few
    /// points from itself depending on the text size.
    private var pitch: some View {
        VStack(spacing: .xLarge) {
            Spacer(minLength: .zero)

            VStack(spacing: .small) {
                Text("welcome.app_name")
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundDefault)

                Text("welcome.tagline")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: .large) {
                WelcomeValueRow(
                    glyph: "book",
                    title: "welcome.value.inventory.title",
                    message: "welcome.value.inventory.body"
                )

                WelcomeValueRow(
                    glyph: "arrow.left.arrow.right",
                    title: "welcome.value.lend.title",
                    message: "welcome.value.lend.body"
                )

                WelcomeValueRow(
                    glyph: "person",
                    title: "welcome.value.borrow.title",
                    message: "welcome.value.borrow.body"
                )
            }

            Spacer(minLength: .zero)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .frame(maxWidth: .infinity)
    }

    /// The two doors and the disclosure under them. The background is the veil's own gradient,
    /// invisible until the pitch scrolls beneath it — and transparent at its top edge, so the
    /// bar has no seam against the wall.
    private var actionsBar: some View {
        VStack(spacing: .medium) {
            Button(action: onSignIn) {
                Text("login.button.signin")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary())
            .accessibilityIdentifier("e2e.welcome.signIn")

            Button(action: onCreateAccount) {
                Text("login.button.create_account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary())

            Text("welcome.footnote")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .background(WelcomeWallBackground.actionsVeil)
    }
}

#Preview {
    NavigationStack {
        WelcomeView(
            coverWall: .init(apiService: APIService(env: .production)),
            onSignIn: {},
            onCreateAccount: {}
        )
    }
    .preferredColorScheme(.dark)
}
