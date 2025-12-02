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

    @State private var username = ""
    @State private var password = "klbC:2n+7HIs"
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
                        dismiss()
                    } catch {
                        errorMessage = (error as? AuthService.AuthError)?.errorDescription ?? error.localizedDescription
                    }
                }
            }, label: {
                Text("Se connecter")
            })
            .padding()
        }
    }
}
