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
//  See PRD 0010 and issue 0056.
//

import SwiftUI

struct AuthField: View {
    let label: LocalizedStringKey
    let contentType: UITextContentType
    let isSecure: Bool
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            Text(label)
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)

            input
                .textContentType(contentType)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .padding(.all, .medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.backgroundSecondary)
                .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium.rawValue))
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
    @Previewable @State var password: String = ""

    VStack(spacing: .medium) {
        AuthField(
            label: "login.username",
            contentType: .username,
            isSecure: false,
            text: $username
        )

        AuthField(
            label: "login.password",
            contentType: .password,
            isSecure: true,
            text: $password
        )
    }
    .padding(.all, .medium)
}
