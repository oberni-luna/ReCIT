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

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: .zero) {
            Spacer()

            // MARK: - Branding
            VStack(spacing: .medium) {
                Image("mainLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)

                VStack(spacing: .xSmall) {
                    Text("Connexion")
                        .textStyle(.title80)
                        .foregroundStyle(.textDefault)

                    Text("Connectez-vous à votre compte inventaire.io")
                        .textStyle(.content300)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // MARK: - Fields
            VStack(spacing: .medium) {
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text("Nom d'utilisateur")
                        .textStyle(.content200Bold)
                        .foregroundStyle(.textSecondary)
                    TextField("", text: $username)
                        .textStyle(.content300)
                        .foregroundStyle(.textDefault)
                        .padding(.medium)
                        .background(.surfaceSecondary)
                        .cornerRadius(.medium)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                VStack(alignment: .leading, spacing: .xSmall) {
                    Text("Mot de passe")
                        .textStyle(.content200Bold)
                        .foregroundStyle(.textSecondary)
                    SecureField("", text: $password)
                        .textStyle(.content300)
                        .foregroundStyle(.textDefault)
                        .padding(.medium)
                        .background(.surfaceSecondary)
                        .cornerRadius(.medium)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .textStyle(.content200)
                        .foregroundStyle(.textError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()

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
                    Text("Se connecter")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    openURL(URL(string: "https://inventaire.io")!)
                } label: {
                    Text("Créer un compte")
                }
                .buttonStyle(ActionButtonStyle(.primary))
            }

            Spacer()
        }
        .padding(.horizontal, .large)
    }
}
