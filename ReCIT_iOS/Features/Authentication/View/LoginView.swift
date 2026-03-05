//
//  FirebaseLoginView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/08/2025.
//
import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let authModel: AuthModel
    let onLogin: () -> Void

    @State private var username = "OlivierB_test"
    @State private var password = "Azerty1234!"
    @State private var errorMessage: String?

    var body: some View {
        Form {
            // MARK: - Fields
            Section {
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text("login.username")
                        .textStyle(.content200Bold)
                        .foregroundStyle(.textSecondary)
                    TextField("", text: $username)
                        .textStyle(.content300)
                        .foregroundStyle(.textDefault)
                        .padding(.all, .medium)
                        .background(.surfaceSecondary)
                        .cornerRadius(.medium)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                VStack(alignment: .leading, spacing: .xSmall) {
                    Text("login.password")
                        .textStyle(.content200Bold)
                        .foregroundStyle(.textSecondary)
                    SecureField("", text: $password)
                        .textStyle(.content300)
                        .foregroundStyle(.textDefault)
                        .padding(.all, .medium)
                        .background(.surfaceSecondary)
                        .cornerRadius(.medium)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .textStyle(.content200)
                        .foregroundStyle(.textError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } header: {
                // MARK: - Branding
                VStack(spacing: .medium) {
                    Image("mainLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)

                    VStack(spacing: .xSmall) {
                        Text("login.title")
                            .textStyle(.title80)
                            .foregroundStyle(.textDefault)

                        Text("login.subtitle")
                            .textStyle(.content300)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            } footer: {
                // MARK: - Actions
                VStack(spacing: .small) {
                    AsyncButton(action: {
                        Task {
                            do {
                                try await authModel.login(username: username, password: password)
                                onLogin()
                            } catch {
                                errorMessage = (error as? AuthService.AuthError)?.errorDescription ?? error.localizedDescription
                            }
                        }
                    }, actionOptions: [.showProgressView], label: {
                        Text("login.button.signin")
                            .frame(maxWidth: .infinity)
                    })
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        openURL(URL(string: "https://inventaire.io/signup")!)
                    } label: {
                        Text("login.button.create_account")
                    }
                    .buttonStyle(ActionButtonStyle(.primary))
                }
            }
        }
        .defaultScrollAnchor(.center)
    }
}
