//
//  AuthField.swift
//  ReCIT_iOS
//
//  A labelled box: the label above, the input on `backgroundSecondary` with a `.medium` radius
//  and `.medium` padding. The Figma library's `Field`, whose two variants are exactly the two
//  view types SwiftUI makes us pick between — `TextField` and `SecureField`.
//
//  It exists rather than the four modifiers being written out per field because the account
//  flow has three forms coming (sign-in here, sign-up in 0057, the reset in 0058) and a box that
//  drifts between them is the kind of difference nobody sees until the screens are side by side.
//
//  The label is written here instead of coming from `withLabel(label:)`, which is what
//  `LoginView` used to use. That modifier draws its label in `caption200`; these screens are
//  drawn in `footnote200`. Changing the shared modifier would restyle the six other forms that
//  consume it for a design that says nothing about them, so the divergence is kept local and
//  written down rather than pushed outward.
//
//  `contentType` is not optional and has no default. It is half the reason this view exists —
//  the project declared no `textContentType` anywhere, which is why signing in used to ignore a
//  password the user already had saved — and a parameter that can be forgotten is one that will
//  be.
//
//  Three optional pieces were added for the sign-up form (issue 0057), and they are optional so
//  that the sign-in screen keeps exactly the box it had. `message` is the error **under this
//  field**: sign-up failures are attributable — a name is taken, an address is malformed — where
//  a refused sign-in belongs to neither box, which is why that screen still says its piece once
//  under both. Drawing the message inside the field rather than beside it is what keeps the
//  rhythm when one of them wraps to three lines: the gap between a field and its own complaint
//  is a `.xSmall`, and it does not become a `.large` just because the sentence got long.
//  `isChecking` is the live check saying so, and `keyboardType` is the address field asking for
//  the right keys.
//
//  See PRD 0010 and issues 0056 and 0057.
//

import SwiftUI

struct AuthField: View {
    let label: LocalizedStringKey
    let contentType: UITextContentType
    let isSecure: Bool
    var keyboardType: UIKeyboardType = .default
    /// Whether a live check is out for what is currently typed.
    var isChecking: Bool = false
    /// What is wrong with this field, when something is. Always one of ours — every sentence
    /// that reaches here comes from `AuthFailure`, never from the server.
    var message: LocalizedStringResource?
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            HStack(spacing: .small) {
                Text(label)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)

                if isChecking {
                    ProgressView()
                        .controlSize(.mini)
                }

                Spacer(minLength: .zero)
            }

            input
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .padding(.all, .medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.backgroundSecondary)
                .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium.rawValue))

            if let message {
                Text(message)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var input: some View {
        if isSecure {
            SecureField("", text: $text)
        } else {
            TextField("", text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }
}

#Preview {
    @Previewable @State var username: String = ""
    @Previewable @State var email: String = ""
    @Previewable @State var password: String = ""

    VStack(spacing: .large) {
        AuthField(
            label: "login.username",
            contentType: .username,
            isSecure: false,
            isChecking: true,
            text: $username
        )

        AuthField(
            label: "signup.email",
            contentType: .emailAddress,
            isSecure: false,
            keyboardType: .emailAddress,
            message: AuthFailure.emailTaken.message,
            text: $email
        )

        AuthField(
            label: "login.password",
            contentType: .newPassword,
            isSecure: true,
            text: $password
        )
    }
    .padding(.all, .medium)
}
