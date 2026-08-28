//
//  CreateAccountView.swift
//  ReCIT_iOS
//
//  « Créer un compte » : a sentence saying whose account this will be, three fields, the button,
//  and the disclosure under it. The same rhythm as « Se connecter », which is next door in the
//  same stack and would look like a different app if it were not.
//
//  **The errors are under the fields, and that is the design.** A sign-in failure belongs to
//  neither box — the server will not say which of the two was wrong, and rightly — so that
//  screen says its piece once, under both. Here every likely failure is attributable: a name is
//  taken, an address is malformed, a password was refused. Saying so above the button would make
//  the user hunt for which box to fix.
//
//  **And they arrive before the button is pressed.** The username and the address are checked
//  against inventaire.io while they are typed, debounced through `.task(id:)`. "Ce nom est déjà
//  pris" is the most likely thing that will go wrong here, and learning it *after* choosing a
//  password is the worst possible place to learn it. The endpoints answer "valid **and**
//  available", so they carry the server's own naming rules and this file restates none of them.
//
//  The state of a field while it is being typed is `FieldAvailability`'s to decide, not this
//  view's — including the case this screen produces constantly and no test would find by
//  accident: an answer for "oliv" landing on a field that now reads "olivier". This view holds
//  the text, hands the type what it needs, and renders what it gets back.
//
//  `.newPassword` makes iOS offer to generate a strong password, which is why
//  `AuthFailure.passwordRejected` exists as its own case: somebody whose *phone* chose the
//  password cannot make anything of "une erreur est survenue".
//
//  See PRD 0010, issue 0057, and the `Créer un compte` frames in the Figma library.
//

import SwiftUI

struct CreateAccountView: View {
    let authModel: AuthModel

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    @State private var usernameCheck: FieldAvailability = .init(field: .username)
    @State private var emailCheck: FieldAvailability = .init(field: .email)

    /// What the submission itself came back with, when it failed. Cleared the moment anything is
    /// retyped — an error about the text that used to be there is worse than no error at all.
    @State private var failure: AuthFailure?

    /// How long a field stays quiet before it is checked. Long enough that a name is not queried
    /// letter by letter — the availability endpoints allow one request a second and answer `429`
    /// past that, which `FieldAvailability` reads as "we do not know" rather than as a refusal,
    /// but a screen that spends its budget on prefixes learns nothing about the whole word.
    private static let checkDelay: Duration = .milliseconds(600)

    var body: some View {
        // One arrangement, and not `ViewThatFits` — see the note in `LoginView`: under a keyboard
        // it rebuilds the `TextField` in another branch and the field loses focus as it is tapped.
        ScrollView {
            form
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            actionsBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundDefault)
        .navigationTitle(Text("login.button.create_account"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: username) {
            await check(username, into: $usernameCheck, with: authModel.usernameAvailability)
        }
        .task(id: email) {
            await check(email, into: $emailCheck, with: authModel.emailAvailability)
        }
        .onChange(of: password) {
            failure = nil
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: .large) {
            Text("signup.subtitle")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            AuthField(
                label: "login.username",
                contentType: .username,
                isSecure: false,
                isChecking: usernameCheck.state == .checking,
                message: message(for: .username, checking: usernameCheck),
                text: $username
            )

            AuthField(
                label: "signup.email",
                contentType: .emailAddress,
                isSecure: false,
                keyboardType: .emailAddress,
                isChecking: emailCheck.state == .checking,
                message: message(for: .email, checking: emailCheck),
                text: $email
            )

            AuthField(
                label: "login.password",
                contentType: .newPassword,
                isSecure: true,
                message: failure?.signupField == .password ? failure?.message : nil,
                text: $password
            )

            // The failures that belong to no field — an unreachable server, a status nobody
            // planned for. They still have to be said somewhere, and the foot of the form is
            // where the sign-in screen says its own.
            if let failure, failure.signupField == nil {
                Text(failure.message)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: .zero)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .frame(maxWidth: .infinity)
    }

    private var actionsBar: some View {
        VStack(spacing: .medium) {
            AsyncButton(
                action: createAccount,
                actionOptions: [.showProgressView],
                label: {
                    Text("signup.button.create")
                        .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.primary())
            .disabled(!canSubmit)

            Text("signup.footnote")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .large)
        .background(.backgroundDefault)
    }

    /// Only what is already known to be wrong holds the button back. A check that never came
    /// back does not: signing up is the user's business, and the server is the authority anyway.
    private var canSubmit: Bool {
        usernameCheck.isFilled
            && !usernameCheck.isRefused
            && emailCheck.isFilled
            && !emailCheck.isRefused
            && !password.isEmpty
    }

    /// What goes under a live-checked field: the submission's verdict when it named this field,
    /// and otherwise whatever the live check last said about it.
    private func message(
        for field: AuthFailure.SignupField,
        checking availability: FieldAvailability
    ) -> LocalizedStringResource? {
        if failure?.signupField == field {
            return failure?.message
        }
        return availability.message
    }

    /// One live check, debounced. Cancelled by `.task(id:)` the moment the text changes, which
    /// is what makes the pause a pause and not a queue — and the answer is filed against the
    /// text it was asked about, so one that outruns its cancellation still cannot paint a field
    /// the user has moved on from.
    private func check(
        _ text: String,
        into availability: Binding<FieldAvailability>,
        with ask: @escaping (String) async -> FieldAvailability.Outcome
    ) async {
        failure = nil
        availability.wrappedValue.edited(to: text)

        guard let query = availability.wrappedValue.pendingQuery else { return }

        do {
            try await Task.sleep(for: Self.checkDelay)
        } catch {
            return
        }

        let outcome: FieldAvailability.Outcome = await ask(query)
        availability.wrappedValue.apply(outcome, for: query)
    }

    private func createAccount() async {
        do {
            try await authModel.signUp(username: username, email: email, password: password)
            failure = nil
        } catch {
            failure = error
        }
    }
}

#Preview {
    NavigationStack {
        CreateAccountView(
            authModel: .init(authService: .init(config: .init(keychainKey: "preview")))
        )
    }
}
