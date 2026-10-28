//
//  EmailConfirmationNotice.swift
//  ReCIT_iOS
//
//  The card at the head of « Compte et connexion » while the address is not confirmed
//  (`Form / Notice`): which address the link went to, and a way to have it sent again.
//

import LBSnackBar
import SwiftUI

struct EmailConfirmationNotice: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.snackBar) private var snackBar

    let email: String

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: .small) {
                Image(systemName: "envelope.badge")
                    .foregroundStyle(.foregroundTinted)

                VStack(alignment: .leading, spacing: .xSmall) {
                    Text("account.unconfirmed.title")
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)

                    Text("account.unconfirmed.body \(email)")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundDefault)

                    AsyncButton(
                        action: resend,
                        actionOptions: [.showProgressView],
                        label: {
                            Text("account.unconfirmed.resend")
                                .textStyle(.action200)
                                .foregroundStyle(.foregroundTinted)
                        }
                    )
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("e2e.account.resendConfirmation")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.all, .sMedium)
            .background(.backgroundTinted)
            .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
    }

    private func resend() async {
        do {
            try await userModel.resendEmailConfirmation()
            snackBar.show {
                SnackBarView(title: String(localized: "account.unconfirmed.sent \(email)"), onDismiss: nil)
            }
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}
