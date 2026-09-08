//
//  LoginView.swift
//  ReCIT_iOS
//
//  « Se connecter » : a lead sentence saying whose account this is, two fields, and the way in.
//
//  It is no longer the app's root — `WelcomeView` is — so it has a navigation bar and a back
//  chevron, and it no longer carries the branding block that used to stand in for a welcome
//  screen. What it keeps is the note under the fields: a sign-in failure belongs to neither
//  field on its own, so it is written once under both rather than attributed to a guess.
//
//  "Créer un compte" **replaces** the stack rather than pushing onto it. From here it is a
//  change of mind, not a step forward, and pushing would let a user build accueil → connexion →
//  création → connexion without ever going back.
//
//  « Mot de passe oublié ? » is neither: it opens as a **sheet** this screen owns (issue 0059).
//  Asking for a link is an errand that interrupts signing in and hands the screen straight back,
//  so it never touches the stack at all — a pull down is the way out, and what is behind it is
//  the half-filled form it was called from.
//
//  The message shown on failure is always ours. `AuthFailure.message` is a catalogue resource in
//  every branch, so the English prose inventaire.io writes in its `message` field has no path to
//  this screen — see the suite on that type.
//
//  **The screen stands on the welcome screen's green** (`278:2`). It is the same doorstep seen
//  from one step further in, and a white form arriving over the wall of covers reads as another
//  app's screen borrowed for the occasion. The green is `backgroundTinted`, and it is the dark
//  value of that token — `AuthFlowView` pins the appearance for this screen as it does for the
//  welcome screen, so every token here resolves dark and the primary button comes out cream
//  without anything being said about it. The navigation bar is painted the same green rather
//  than left to its default material, which would lay a grey pane across the top of it, and the
//  green is drawn behind every safe area — the keyboard included, or its translucency shows the
//  window's black through it.
//
//  The bottom bar's own top edge is **faded in** (`AuthActionsBackground`) rather than drawn as a
//  line the form disappears behind.
//
//  What does *not* follow into the dark is the inside of the fields: `AuthField(isOnTinted:)`
//  pins its box back to the light appearance, so the paper stays white and the ink stays dark.
//
//  See PRD 0010, issues 0056, 0058 and 0059, and the `Se connecter` frames in the Figma library.
//

import SwiftUI

struct LoginView: View {
    let authModel: AuthModel

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var failure: AuthFailure?
    @State private var isAskingForResetLink: Bool = false

    var body: some View {
        // One arrangement, deliberately. The form scrolls when it does not fit and sits still
        // when it does, and the actions stay pinned either way.
        //
        // **Not `ViewThatFits`**, which the onboarding screens use for the problem that looks
        // like this one. On a screen with a keyboard it is a focus bug: raising the keyboard
        // shrinks the available height, `ViewThatFits` picks a different branch, and the
        // `TextField` is rebuilt at a different place in the view tree. SwiftUI reads that as a
        // different view, drops the focus and dismisses the keyboard — which made the username
        // field impossible to type into at all. The onboarding screens are safe because nothing
        // on them raises a keyboard.
        ScrollView {
            form
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            actionsBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Behind the keyboard too. `background(_:ignoresSafeAreaEdges:)` ignores the *container*
        // safe area and stops at the keyboard's, which left the window's own black showing
        // through a raised keyboard — visible, because the keyboard is translucent.
        .background {
            DesignSystem.Color.backgroundTinted.color
                .ignoresSafeArea()
        }
        .navigationTitle(Text("login.button.signin"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.Color.backgroundTinted.color, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isAskingForResetLink) {
            NavigationStack {
                ForgotPasswordView(authModel: authModel)
            }
            // Full height: the sheet carries a keyboard and a pinned button, and a medium detent
            // that grows as the keyboard rises moves the button mid-tap.
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            // Sheets are presented outside this stack, so `AuthFlowView`'s pin does not reach
            // them. Stated again here, or the green screen would come up in the light appearance
            // with a grey navigation bar over it.
            .preferredColorScheme(.dark)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: .large) {
            // `foregroundDefault`, not `foregroundSecondary`: on `green/900` the secondary veil
            // gives 4.5:1, just under AA for a sentence at this size.
            Text("login.subtitle")
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                // The subtitle carries a markdown link to inventaire.io. Links keep the tint,
                // not the `foregroundStyle`, so the tint is what has to read on `green/900`.
                .tint(.foregroundTinted)
                .frame(maxWidth: .infinity, alignment: .leading)

            AuthField(
                label: "login.username",
                contentType: .username,
                isSecure: false,
                isOnTinted: true,
                text: $username
            )

            AuthField(
                label: "login.password",
                contentType: .password,
                isSecure: true,
                isOnTinted: true,
                text: $password
            )

            if let failure {
                Text(failure.message)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Read back by the end-to-end scenario when the session never opens, so its
                    // report carries what the screen actually said instead of "rien ne s'est
                    // passé".
                    .accessibilityIdentifier("e2e.login.failure")
            }

            // Under the password box, where somebody who has just failed to remember one is
            // already looking — and not in the bar below, which is where the two doors out of
            // this screen live and where a third choice would dilute both.
            Button {
                isAskingForResetLink = true
            } label: {
                Text("login.button.forgot_password")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundTinted)
            }

            Spacer(minLength: .zero)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .frame(maxWidth: .infinity)
    }

    private var actionsBar: some View {
        AsyncButton(
            action: signIn,
            actionOptions: [.showProgressView],
            label: {
                Text("login.button.signin")
                    .frame(maxWidth: .infinity)
            }
        )
        .buttonStyle(.primary())
        // Held back until there is a name to sign in with, the way the create-account button is
        // held back. An empty form pressing a live button only ever earns a round trip and a
        // refusal — and inventaire.io rate-limits sign-ins, so that refusal is not free.
        .disabled(username.isEmpty)
        .accessibilityIdentifier("e2e.login.submit")
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .background { AuthActionsBackground() }
    }

    private func signIn() async {
        do {
            try await authModel.login(username: username, password: password)
            failure = nil
        } catch {
            failure = error
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(
            authModel: .init(authService: .init(config: .init(keychainKey: "preview")))
        )
    }
    // As `AuthFlowView` pins it: this screen is green in both system appearances.
    .preferredColorScheme(.dark)
}
