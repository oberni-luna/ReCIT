//
//  FirebaseLoginView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/08/2025.
//
import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    let authModel: AuthModel
    let onLogin: () -> Void
    
    @State private var username = "OlivierB_test"
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if let errorMessage {
                Text("⚠️ Error: \(errorMessage)")
            }

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

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
            })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
