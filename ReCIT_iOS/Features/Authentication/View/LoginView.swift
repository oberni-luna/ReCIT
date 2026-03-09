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

                TextField("", text: $username)
                    .textStyle(.content300)
                    .padding(.all, .medium)
                    .background(.backgroundSecondary)
                    .cornerRadius(.medium)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "login.username")

                SecureField("", text: $password)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .padding(.all, .medium)
                    .background(.backgroundSecondary)
                    .cornerRadius(.medium)
                    .withLabel(label: "login.password")

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
                        .frame(height: 128)
                        .cornerRadius(.roundedLarge)

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
                .padding(.horizontal, .large)
                .padding(.top, .large)
                .frame(maxWidth: .infinity)

            } footer: {
                // MARK: - Actions
                VStack(spacing: .sMedium) {
                    Spacer(minLength: 16)

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
                    })
                    .buttonStyle(.primary())

                    Button {
                        openURL(URL(string: "https://inventaire.io/signup")!)
                    } label: {
                        Text("login.button.create_account")
                    }
                    .buttonStyle(.secondary())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .defaultScrollAnchor(.center)
        .applyListBackground()
    }
}
