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
                        .textStyle(.footnote200Bold)
                        .foregroundStyle(.foregroundSecondary)

                    TextField("", text: $username)
                        .textStyle(.content300)
                        .padding(.all, .medium)
                        .background(.backgroundSecondary)
                        .cornerRadius(.medium)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.foregroundDefault)
                }

                VStack(alignment: .leading, spacing: .xSmall) {
                    Text("login.password")
                        .textStyle(.footnote200Bold)
                        .foregroundStyle(.foregroundSecondary)
                    SecureField("", text: $password)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .padding(.all, .medium)
                        .background(.backgroundSecondary)
                        .cornerRadius(.medium)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundError)
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
                            .textStyle(.title50)
                            .foregroundStyle(.foregroundDefault)

                        Text("login.subtitle")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundSecondary)
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
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .defaultScrollAnchor(.center)
    }
}
