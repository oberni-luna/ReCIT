//
//  PasswordResetSentView.swift
//  ReCIT_iOS
//
//  The confirmation: an envelope, a title, one sentence, and the way back to signing in.
//
//  **The sentence is conditional, and that is the whole screen.** It reads « **si** un compte
//  existe pour cette adresse, un e-mail vient de partir » — never "e-mail envoyé", never
//  "adresse inconnue". Telling those two apart would turn this into a way of asking "does this
//  account exist?" about any address somebody cares to type: run a list through the form, read
//  the answers off this screen.
//
//  inventaire.io itself does distinguish them — it answers `400` for an address it has no user
//  for — so the careful wording cannot be left to the server. It is written here, and the
//  collapsing happens in `PasswordResetOutcome` before this view is ever reached: there is
//  exactly one sentence in this file, so there is no second one to leak.
//
//  The address is named back because a confirmation that does not is one nobody can check for a
//  typo — and a typo is the likeliest reason the mail never arrives. It is the user's own text
//  going back to the user.
//
//  Centred, and scrolling when it has to: at an accessibility text size four stacked elements
//  are taller than a small phone, and the button is the only way out of this screen.
//
//  See PRD 0010, issue 0058, and the `Mot de passe oublié` confirmation frames in the Figma
//  library.
//

import SwiftUI

struct PasswordResetSentView: View {

    /// The address that was submitted. Written into the sentence, and used for nothing else.
    let address: String

    /// Back to signing in — forward, rather than back to the box that has just been emptied.
    let onBackToSignIn: () -> Void

    /// The design's 48pt glyph, following Dynamic Type so it stays proportionate to the title
    /// under it. Same treatment as `WelcomeValueRow`'s.
    @ScaledMetric(relativeTo: .title) private var glyphSize: CGFloat = 48

    var body: some View {
        ViewThatFits(in: .vertical) {
            VStack(spacing: .zero) {
                confirmation

                actionsBar
            }

            ScrollView {
                confirmation
            }
            .frame(idealHeight: .zero, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                actionsBar
            }

            ScrollView {
                VStack(spacing: .zero) {
                    confirmation

                    actionsBar
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
        .navigationTitle(Text(verbatim: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var confirmation: some View {
        VStack(spacing: .large) {
            Spacer(minLength: .zero)

            Image(systemName: "envelope")
                .resizable()
                .scaledToFit()
                .frame(width: glyphSize, height: glyphSize)
                .foregroundStyle(.foregroundTinted)

            VStack(spacing: .medium) {
                Text("reset.sent.title")
                    .textStyle(.title50)
                    .foregroundStyle(.foregroundDefault)

                // The one sentence, and it comes from the type that owns the rule rather than
                // being written out here — so a future edit to this screen cannot quietly turn
                // it into a statement about the address.
                //
                // Resolved to a `String` first, which is what stops SwiftUI treating the
                // sentence as markdown: left as a localised key it detects the address inside
                // it and draws a tinted `mailto:` link, so the confirmation ended up offering to
                // compose an email to the very address it is being careful about.
                if let body = PasswordResetOutcome.submitted.confirmation(for: address) {
                    Text(String(localized: body))
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
            .multilineTextAlignment(.center)

            Spacer(minLength: .zero)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .frame(maxWidth: .infinity)
    }

    private var actionsBar: some View {
        Button(action: onBackToSignIn) {
            Text("reset.sent.button")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary())
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .frame(maxWidth: .infinity)
        .background(.backgroundDefault)
    }
}

#Preview {
    NavigationStack {
        PasswordResetSentView(address: "alice@example.org", onBackToSignIn: {})
    }
}
