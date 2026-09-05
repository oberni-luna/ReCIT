//
//  WelcomeView.swift
//  ReCIT_iOS
//
//  What the app is for, said before anyone is asked who they are: the name, a tagline, one
//  sentence, and the two doors — over a wall of book covers (PRD 0011).
//
//  **The text sits on the floor of the screen, and is built from the bottom up.** The wall is
//  the picture; a block of copy floating in the middle of it competes with the covers behind it
//  and reads as a caption laid over a photograph. Bottom-aligned, the wall gets the top two
//  thirds, the veil closes under the text, and the eye lands on « Se connecter » — which is what
//  most people opened the app for. Three groups, `spacing/large` apart: the headline, the two
//  actions, the inventaire.io note (`265:7532`).
//
//  The three glyph-and-paragraph value rows are gone with that move, replaced by the single
//  sentence they said between them. Nine lines of pitch over a picture is a page of text with a
//  wall behind it; one sentence is a promise. `WelcomeValueRow` went with them.
//
//  **The actions may never leave the screen.** On a 667pt phone at an accessibility text size
//  the block is taller than the display, so the screen takes the first of two arrangements that
//  fits: standing on the floor, then scrolling — still anchored to the bottom, so what is on
//  screen when it opens is still the doors.
//
//  The inventaire.io note stays **under the buttons** rather than above the headline. It
//  qualifies « Créer un compte » — the account being created is not this app's, and the covers
//  above are other people's books — and a disclosure that scrolls away from the button it
//  qualifies is a disclosure that was not made.
//
//  The screen is dark **in both system appearances** — `AuthFlowView` pins the appearance while
//  this screen is the stack's root, which is also what turns the status bar's glyphs white.
//  Every colour here is a token; they simply resolve to their dark values, which is how the
//  primary button comes out cream (`background/tinted-inverse` is `green/200` in the dark).
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
            // 1. The block stands on the floor of the screen, the wall drifting above it. At the
            //    sizes this screen was drawn for there is no scroll view in the tree at all.
            VStack(spacing: .zero) {
                Spacer(minLength: .zero)

                content
            }

            // 2. Past the largest accessibility sizes the block is taller than the phone. It
            //    scrolls, anchored to its bottom: the screen still opens on the two doors rather
            //    than on the top of a paragraph.
            ScrollView {
                content
            }
            .defaultScrollAnchor(.bottom)
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

    /// The three groups, written once and carried by both arrangements — a second copy of these
    /// paddings is how the same screen comes to sit a few points from itself depending on the
    /// text size.
    private var content: some View {
        VStack(spacing: .large) {
            headline

            actions

            note
        }
    }

    /// The name, the tagline, and the sentence that replaced the three value rows.
    private var headline: some View {
        VStack(spacing: .medium) {
            VStack(spacing: .xSmall) {
                Text("welcome.app_name")
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundDefault)

                Text("welcome.tagline")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundTinted)
            }

            Text("welcome.pitch")
                .textStyle(.content400)
                .foregroundStyle(.foregroundDefault)
                .padding(.horizontal, .small)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, .medium)
    }

    /// The two doors. No spacing between them: the secondary style's own padding is the gap, and
    /// it is also what keeps « Créer un compte » a full-height touch target rather than a
    /// 23-point line of text.
    private var actions: some View {
        VStack(spacing: .zero) {
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
        }
        .padding(.horizontal, .medium)
    }

    /// Where the covers come from, and where the account will live.
    private var note: some View {
        Text("welcome.footnote")
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .medium)
            .padding(.vertical, .sMedium)
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
